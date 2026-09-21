#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <stdarg.h>
#import <dlfcn.h>
#import "XYABSettingsViewController.h"

// ── 接口声明 ──
// 签名严格照闲鱼 7.28.30 的头文件。类型写错（比如把 double / long long 当 id）
// 会让 %orig 或日志直接把数值当指针解引用 → 闪退。

@interface FMAboutViewController : UIViewController
@end

@interface FMSplashModule : NSObject
@property (retain, nonatomic) UIWindow *window;
@property (readonly, nonatomic) BOOL isADShowing;
+ (id)sharedInstance;
- (void)showSplashView;
- (void)fishSplashAdDidFinish;
- (void)fishSplashAdDidShow;
- (void)loadAd;
- (void)applicationDidBecomeActive:(id)n;
- (void)applicationDidEnterBackground:(id)n;
@end

// 「后台冻结 → 回前台」那条热启动链路（闲鱼自 7.28.x 起新增）
@interface FMHomeRefreshHelper : NSObject
@property (nonatomic) double lastEnterBackgroundTime;
@property (nonatomic) long long hotStartMinMinutes;
- (void)handleAppWillEnterForeground;
- (void)requestHotStartDecide:(long long)arg;
- (void)handleHotStartDecideResult:(id)result backgroundMinutes:(long long)minutes;
- (void)postHotStartRefreshHomeNotification;
- (BOOL)isHotStartFatigueExhaustedToday;
@end

// ── 偏好存储 ──

static NSString * const kDomain    = @"im.mjh.xianyuadblock";
static NSString * const kKeyFeedAd = @"feedAdFilterEnabled";

static BOOL _getBool(NSString *key, BOOL def) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
    CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                     (__bridge CFStringRef)kDomain);
    if (!v) return def;
    BOOL r = [(__bridge NSNumber *)v boolValue];
    CFRelease(v);
    return r;
}
static BOOL isFeedAdFilterOn(void) { return _getBool(kKeyFeedAd, YES); }

// 热启动日志函数定义在文件后部（见「热启动开屏广告」一节），这里先声明，
// 供前面的冷启动区块记日志用。
static void HotLog(NSString *fmt, ...);

// ── ====== 搜索广告过滤 ====== ──

static char kAdIPsByCVKey;
static NSMutableSet *_adIPsForCV(id cv) {
    NSMutableSet *s = objc_getAssociatedObject(cv, &kAdIPsByCVKey);
    if (!s) { s = [NSMutableSet set]; objc_setAssociatedObject(cv, &kAdIPsByCVKey, s, OBJC_ASSOCIATION_RETAIN); }
    return s;
}

static BOOL _scanAdText(UIView *view, int depth) {
    if (depth > 8) return NO;
    if ([view isKindOfClass:[UILabel class]] && [[(UILabel *)view text] isEqualToString:@"广告"]) return YES;
    for (UIView *sub in view.subviews) {
        if (_scanAdText(sub, depth + 1)) return YES;
    }
    return NO;
}

static IMP _origSizeIMP;
static void _ensureSizeSwizzled(id delegate) {
    Class cls = [delegate class];
    if ([objc_getAssociatedObject(cls, &kAdIPsByCVKey) boolValue]) return;
    objc_setAssociatedObject(cls, &kAdIPsByCVKey, @YES, OBJC_ASSOCIATION_RETAIN);

    SEL sel = @selector(collectionView:layout:sizeForItemAtIndexPath:);
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;

    _origSizeIMP = method_getImplementation(m);
    IMP newImp = imp_implementationWithBlock(^(id self, id cv, id layout, NSIndexPath *ip) {
        if (isFeedAdFilterOn()) {
            NSMutableSet *adIPs = _adIPsForCV(cv);
            if ([adIPs containsObject:ip]) return (CGSize){0, 0};
        }
        CGSize (*fn)(id, SEL, id, id, NSIndexPath *) = (CGSize (*)(id, SEL, id, id, NSIndexPath *))_origSizeIMP;
        return fn(self, sel, cv, layout, ip);
    });
    method_setImplementation(m, newImp);
}

// 所有 %hook 收进一个 group。理由见文件末尾 %ctor 的注释：
// 巨魔注入进没有 Substrate 的环境时，弱链接的 MSHookMessageEx 是 NULL，
// 无条件 %init 会调到地址 0 直接崩。
%group XYHHooks

%hook UICollectionViewCell
- (void)prepareForReuse {
    %orig;
    if (!isFeedAdFilterOn()) return;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"WaterfallItemCell"] || [cls containsString:@"SingleRowItemCell"]) {
        self.hidden = NO; self.alpha = 1;
    }
}
- (void)layoutSubviews {
    %orig;
    if (!isFeedAdFilterOn()) return;
    NSString *cls = NSStringFromClass([self class]);
    if (!([cls containsString:@"WaterfallItemCell"] || [cls containsString:@"SingleRowItemCell"])) return;
    if (!_scanAdText(self, 0)) return;

    self.hidden = YES; self.alpha = 0;
    id cv = [self valueForKey:@"_collectionView"];
    NSIndexPath *ip = [cv indexPathForCell:(id)self];
    if (!ip) return;
    NSMutableSet *set = _adIPsForCV(cv);
    if ([set containsObject:ip]) return;
    [set addObject:ip];
    id delegate = [cv delegate];
    if (delegate) _ensureSizeSwizzled(delegate);
    [[cv valueForKey:@"collectionViewLayout"] invalidateLayout];
}
%end

// ── ====== TableView 代理拦截器 ====== ──

@interface _XYHTableProxy : NSObject <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) id target;
@property (nonatomic, weak) UIViewController *sourceVC;
@end

@implementation _XYHTableProxy

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    if ([self.target respondsToSelector:@selector(numberOfSectionsInTableView:)])
        return [self.target numberOfSectionsInTableView:tv];
    return 1;
}
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    NSInteger c = [self.target tableView:tv numberOfRowsInSection:s];
    return (s == [self numberOfSectionsInTableView:tv] - 1) ? c + 1 : c;
}
- (NSInteger)_injectedRowForTableView:(UITableView *)tv section:(NSInteger)s {
    if (s == [self numberOfSectionsInTableView:tv] - 1)
        return [self.target tableView:tv numberOfRowsInSection:s];
    return -1;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSInteger r = [self _injectedRowForTableView:tv section:ip.section];
    if (r >= 0 && ip.row == r) {
        UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"_XYH"];
        if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"_XYH"];
        c.textLabel.text = @"闲鱼去广告助手";
        c.textLabel.font = [UIFont systemFontOfSize:17];
        c.detailTextLabel.text = @"v1.0.0";
        c.detailTextLabel.font = [UIFont systemFontOfSize:14];
        c.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return c;
    }
    return [self.target tableView:tv cellForRowAtIndexPath:ip];
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NSInteger r = [self _injectedRowForTableView:tv section:ip.section];
    if (r >= 0 && ip.row == r) {
        [tv deselectRowAtIndexPath:ip animated:YES];
        if (![self.sourceVC.navigationController.topViewController isKindOfClass:[XYABSettingsViewController class]]) {
            XYABSettingsViewController *vc = [[XYABSettingsViewController alloc] init];
            [self.sourceVC.navigationController pushViewController:vc animated:YES];
        }
        return;
    }
    if ([self.target respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
        [self.target tableView:tv didSelectRowAtIndexPath:ip];
}
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    if ([self _injectedRowForTableView:tv section:ip.section] == ip.row) return 48;
    if ([self.target respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
        return [self.target tableView:tv heightForRowAtIndexPath:ip];
    return 44;
}
- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s {
    if ([self.target respondsToSelector:@selector(tableView:heightForHeaderInSection:)])
        return [self.target tableView:tv heightForHeaderInSection:s];
    return UITableViewAutomaticDimension;
}
- (CGFloat)tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)s {
    if ([self.target respondsToSelector:@selector(tableView:heightForFooterInSection:)])
        return [self.target tableView:tv heightForFooterInSection:s];
    return UITableViewAutomaticDimension;
}
- (id)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    if ([self.target respondsToSelector:@selector(tableView:titleForFooterInSection:)])
        return [self.target tableView:tv titleForFooterInSection:s];
    return nil;
}
- (id)tableView:(UITableView *)tv viewForFooterInSection:(NSInteger)s {
    if ([self.target respondsToSelector:@selector(tableView:viewForFooterInSection:)])
        return [self.target tableView:tv viewForFooterInSection:s];
    return nil;
}
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [self.target respondsToSelector:aSelector];
}
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector] ? self.target : [super forwardingTargetForSelector:aSelector];
}
@end

// ── ====== 设置页入口: FMAboutViewController ====== ──

%hook FMAboutViewController
- (void)viewDidLoad {
    %orig;
    UITableView *tv = [self valueForKey:@"_tableView"];
    if (!tv || [tv.dataSource isKindOfClass:[_XYHTableProxy class]]) return;
    _XYHTableProxy *proxy = [[_XYHTableProxy alloc] init];
    proxy.target = (id)(tv.dataSource) ?: (id)self;
    proxy.sourceVC = self;
    objc_setAssociatedObject(tv, @selector(viewDidAppear:), proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    tv.dataSource = proxy;
    tv.delegate = proxy;
    [tv reloadData];
}
%end

// ── ====== 开屏广告拦截 ====== ──

static NSString * const kKeySplash = @"splashAdBlocked";
static BOOL isSplashAdBlocked(void) { return _getBool(kKeySplash, YES); }

%hook FMSplashModule

- (void)loadAd {
    HotLog(@"→ FMSplashModule loadAd");
    %orig;
}

- (void)showSplashView {
    // 热启动广告如果也走这条（冷启动那条），日志里会看到它紧跟 handleAppWillEnterForeground 之后
    HotLog(@"→ FMSplashModule showSplashView  isADShowing=%d", self.isADShowing);
    if (isSplashAdBlocked()) {
        // 让原始流程跑完（状态栏等初始化正常），然后立刻清理
        %orig;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fishSplashAdDidFinish];
        });
        return;
    }
    %orig;
}

- (void)fishSplashAdDidShow {
    HotLog(@"→ FMSplashModule fishSplashAdDidShow");
    %orig;
}

- (void)fishSplashAdDidFinish {
    HotLog(@"→ FMSplashModule fishSplashAdDidFinish");
    %orig;
}

%end

// ── ====== 热启动开屏广告（后台冻结 → 回前台弹的那种）====== ──
//
// 和冷启动那条不是同一条链路。7.28.30 上实际确认的调用链：
//
//   FMHomeRefreshHelper.handleAppWillEnterForeground      回前台入口
//     ├─ hotStartMinMinutes / lastEnterBackgroundTime     判断后台待了多久
//     ├─ requestHotStartDecide:                           向服务端要决策（参数是后台分钟数）
//     ├─ handleHotStartDecideResult:backgroundMinutes:    ← 决策回调，广告在这里出
//     └─ postHotStartRefreshHomeNotification              （同一函数里还有正常的首页刷新）
//
// 展示由 FishAd.FishSplashAdLoader / FishSplashAdWindow 负责；
// FishSplashAdConfig.disableHotStartAd 是闲鱼自带的热启动广告开关。

static NSString * const kKeyHotStartAd  = @"hotStartAdBlocked";
static NSString * const kKeyHotStartLog = @"hotAdDebugLog";
static NSString * const kKeyHotStartCfg = @"hotAdUseConfigSwitch";
static BOOL isHotStartAdBlocked(void) { return _getBool(kKeyHotStartAd, YES); }
static BOOL isHotStartLogOn(void)     { return _getBool(kKeyHotStartLog, NO); }
// 关掉「调 App 自带开关」这条路（只留拆窗口兜底）的逃生阀
static BOOL isHotStartConfigSwitchOn(void) { return _getBool(kKeyHotStartCfg, YES); }

// 日志：roothide 沙盒下 /var/mobile 不一定写得进，逐级回退
static NSString *gHotLogPath = nil;
static void hotLogInit(void) {
    if (gHotLogPath) return;
    NSString *home = NSHomeDirectory();
    NSArray<NSString *> *cands = @[
        @"/var/mobile/Documents/xyh_hotad.log",
        [home stringByAppendingPathComponent:@"Documents/xyh_hotad.log"],
    ];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *p in cands) {
        [fm createDirectoryAtPath:[p stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES attributes:nil error:nil];
        if (![fm fileExistsAtPath:p]) [fm createFileAtPath:p contents:nil attributes:nil];
        if ([fm isWritableFileAtPath:p]) { gHotLogPath = p; break; }
    }
}

static void HotLog(NSString *fmt, ...) {
    if (!isHotStartLogOn()) return;
    va_list ap; va_start(ap, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[闲鱼去广告助手] %@", msg);
    hotLogInit();
    if (!gHotLogPath) return;
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:gHotLogPath];
    if (!fh) return;
    [fh seekToEndOfFile];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HH:mm:ss.SSS";
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n",
                      [df stringFromDate:[NSDate date]], msg];
    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

// 关掉闲鱼自带的热启动广告开关。配置可能被服务端下发覆盖，所以回前台再补一次。
static void disableHotStartAdConfig(NSString *why) {
    Class cfg = NSClassFromString(@"_TtC6FishAd18FishSplashAdConfig");
    if (!cfg) { HotLog(@"%@ 找不到 FishSplashAdConfig", why); return; }
    SEL sShared = NSSelectorFromString(@"shared");
    if (![cfg respondsToSelector:sShared]) { HotLog(@"%@ 无 +shared", why); return; }
    id shared = ((id (*)(id, SEL))objc_msgSend)((id)cfg, sShared);
    if (!shared) { HotLog(@"%@ shared = nil", why); return; }

    SEL sGet = NSSelectorFromString(@"disableHotStartAd");
    SEL sSet = NSSelectorFromString(@"setDisableHotStartAd:");
    if (![shared respondsToSelector:sSet]) {
        HotLog(@"%@ 实例不响应 setDisableHotStartAd:", why);
        return;
    }
    BOOL before = [shared respondsToSelector:sGet]
                ? ((BOOL (*)(id, SEL))objc_msgSend)(shared, sGet) : NO;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(shared, sSet, YES);
    BOOL after = [shared respondsToSelector:sGet]
               ? ((BOOL (*)(id, SEL))objc_msgSend)(shared, sGet) : NO;
    HotLog(@"%@ disableHotStartAd: %d → %d", why, before, after);
}

// UIApplication.windows 自 iOS 15 起废弃（且被当 error），改用 UIScene
static NSArray<UIWindow *> *xyhAllWindows(void) {
    NSMutableArray<UIWindow *> *out = [NSMutableArray array];
    for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
        if ([sc isKindOfClass:[UIWindowScene class]])
            [out addObjectsFromArray:((UIWindowScene *)sc).windows];
    }
    return out;
}

// 兜底：真弹出来了就把开屏窗口拆掉并通知模块结束
static void tearDownHotSplash(NSString *why) {
    id mod = nil;
    Class mcls = NSClassFromString(@"FMSplashModule");
    if (mcls && [mcls respondsToSelector:@selector(sharedInstance)])
        mod = ((id (*)(id, SEL))objc_msgSend)((id)mcls, @selector(sharedInstance));

    BOOL hit = NO;
    if (mod && [mod respondsToSelector:@selector(window)]) {
        UIWindow *w = ((id (*)(id, SEL))objc_msgSend)(mod, @selector(window));
        if (w) {
            HotLog(@"%@ 拆模块窗口 %@", why, NSStringFromClass([w class]));
            w.hidden = YES;
            hit = YES;
        }
    }
    for (UIWindow *w in xyhAllWindows()) {
        NSString *cls = NSStringFromClass([w class]);
        if ([cls rangeOfString:@"Splash" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            HotLog(@"%@ 拆窗口 %@ level=%.0f hidden=%d", why, cls, w.windowLevel, w.isHidden);
            w.hidden = YES;
            hit = YES;
        }
    }
    if (mod && [mod respondsToSelector:@selector(fishSplashAdDidFinish)]) {
        HotLog(@"%@ 调 fishSplashAdDidFinish", why);
        [mod fishSplashAdDidFinish];
        hit = YES;
    }
    if (!hit) HotLog(@"%@ 没找到开屏窗口", why);
}

%hook FMHomeRefreshHelper

- (void)handleAppWillEnterForeground {
    // ⚠️ 必须在 %orig 之前把开关按回去。
    // 日志实测：App 在 handleAppWillEnterForeground 这一瞬间就读 disableHotStartAd，
    // 紧接着 requestHotStartDecide: 就发出去了；而 DidBecomeActive 比它晚约 220ms，
    // 在那边按开关根本来不及（03:45:28.537 请求 → 03:45:28.761 才按回 1）。
    if (isHotStartAdBlocked() && isHotStartConfigSwitchOn())
        disableHotStartAdConfig(@"[回前台·前置]");

    HotLog(@"→ handleAppWillEnterForeground minMinutes=%lld lastBg=%.1f",
           self.hotStartMinMinutes, self.lastEnterBackgroundTime);
    %orig;
}

- (void)requestHotStartDecide:(long long)arg {
    HotLog(@"→ requestHotStartDecide:%lld", arg);
    %orig;
}

- (void)handleHotStartDecideResult:(id)result backgroundMinutes:(long long)minutes {
    HotLog(@"→ handleHotStartDecideResult: bg=%lld", minutes);
    %orig;
    if (isHotStartAdBlocked()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            tearDownHotSplash(@"  [热启动兜底]");
        });
    }
}

- (void)postHotStartRefreshHomeNotification {
    HotLog(@"→ postHotStartRefreshHomeNotification");
    %orig;
}

%end   // FMHomeRefreshHelper

%end   // %group XYHHooks

// ── ====== %ctor ====== ──
//
// ⚠️ 血泪教训：dyld 初始化阶段（%ctor 里）**绝对不能碰闲鱼自己的类**。
//
// FishSplashAdConfig 是 Swift 类，它的初始化链路会走到 MMKV（腾讯 KV 库，
// 头文件里的 FishAd.FishMMKVHandler）。MMKV 需要 App 容器/路径都已就绪，
// 在 dyld init 里调它 → mmkvWithID 里解引用空指针（far=0x8）→ 启动即闪退。
//
// 所以 %ctor 只做最轻的事（bundleId 判断 + 注册通知），真正的初始化推迟到
// App 起来并且第一次回前台之后。

static void XYHHotStartSetup(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (isHotStartLogOn()) {
            hotLogInit();
            HotLog(@"===== 注入成功  开屏=%@ 热启动=%@ 日志=%@",
               isSplashAdBlocked() ? @"拦截" : @"放行",
               isHotStartAdBlocked() ? @"拦截" : @"放行",
                   gHotLogPath ?: @"(无，只走 NSLog)");
        }
        if (isHotStartAdBlocked() && isHotStartConfigSwitchOn())
            disableHotStartAdConfig(@"[启动]");
    });
}

%ctor {
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.taobao.fleamarket"]) return;
        NSLog(@"[闲鱼去广告助手] 闲鱼去广告助手已注入");

        // CydiaSubstrate 是弱链接（工程可能被巨魔注入器注入到 Runner.app/Frameworks/，
        // 那里没有 .jbroot，rpath 解析不到 Substrate）。符号为 NULL 时绝不能 %init，
        // 否则 Logos 调用 MSHookMessageEx 会跳到地址 0 → 启动即闪退。
        if (dlsym(RTLD_DEFAULT, "MSHookMessageEx") && dlsym(RTLD_DEFAULT, "MSHookFunction")) {
            %init(XYHHooks);
        } else {
            NSLog(@"[闲鱼去广告助手] 当前进程没有 CydiaSubstrate，跳过 hook 安装（插件不生效但不会崩）");
        }

        // 只注册通知，不碰 App 的任何类
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *n) {
            static dispatch_once_t firstTime;
            __block BOOL isFirst = NO;
            dispatch_once(&firstTime, ^{ isFirst = YES; });
            if (isFirst) {
                // 首次回前台时 App 可能还在收尾，再缓 1 秒才碰它的类
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{ XYHHotStartSetup(); });
                return;
            }
            // 配置可能被服务端下发覆盖，之后每次回前台都补一次
            if (isHotStartAdBlocked() && isHotStartConfigSwitchOn())
                disableHotStartAdConfig(@"[回前台]");
        }];
    }
}
