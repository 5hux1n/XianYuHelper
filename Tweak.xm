#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "XYHSettingsViewController.h"

// ── 接口声明 ──

@interface FMSplashModule : NSObject
- (void)showSplashView;
- (void)fishSplashAdDidFinish;
@end

@interface FMAboutViewController : UIViewController
@end

// ── 偏好存储 ──

static NSString * const kDomain    = @"im.mjh.fishhook";
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
        c.textLabel.text = @"咸鱼助手";
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
        if (![self.sourceVC.navigationController.topViewController isKindOfClass:[XYHSettingsViewController class]]) {
            XYHSettingsViewController *vc = [[XYHSettingsViewController alloc] init];
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
- (void)showSplashView {
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
%end

// ── ====== %ctor ====== ──

%ctor {
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid isEqualToString:@"com.taobao.fleamarket"]) return;
        NSLog(@"[FishHook] 咸鱼助手已注入闲鱼 App");
        NSLog(@"[FishHook] 开屏广告: %@", isSplashAdBlocked() ? @"拦截" : @"放行");
    }
}
