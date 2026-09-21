#import "XYABSettingsViewController.h"

static NSString * const kDomain    = @"im.mjh.xianyuadblock";
static NSString * const kKeySplash = @"splashAdBlocked";
static NSString * const kKeyFeedAd = @"feedAdFilterEnabled";

@interface XYABSettingsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation XYABSettingsViewController

+ (BOOL)_getBool:(NSString *)key default:(BOOL)def {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
    CFPropertyListRef v = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                     (__bridge CFStringRef)kDomain);
    if (!v) return def;
    BOOL r = [(__bridge NSNumber *)v boolValue];
    CFRelease(v);
    return r;
}
+ (void)_setBool:(BOOL)val forKey:(NSString *)key {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, val ? kCFBooleanTrue : kCFBooleanFalse,
                             (__bridge CFStringRef)kDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
}
+ (BOOL)isSplashAdBlocked { return [self _getBool:kKeySplash default:YES]; }
+ (void)setSplashAdBlocked:(BOOL)v { [self _setBool:v forKey:kKeySplash]; }
+ (BOOL)isFeedAdFilterOn { return [self _getBool:kKeyFeedAd default:YES]; }
+ (void)setFeedAdFilterOn:(BOOL)v { [self _setBool:v forKey:kKeyFeedAd]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"闲鱼去广告助手";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    [self.view addSubview:self.tableView];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
    ]];

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 24, header.bounds.size.width, 30)];
    title.text = @"🐟 闲鱼去广告助手";
    title.font = [UIFont boldSystemFontOfSize:24];
    title.textAlignment = NSTextAlignmentCenter;
    [header addSubview:title];
    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(0, 56, header.bounds.size.width, 22)];
    sub.text = @"让闲鱼更清爽";
    sub.font = [UIFont systemFontOfSize:14];
    sub.textColor = [UIColor secondaryLabelColor];
    sub.textAlignment = NSTextAlignmentCenter;
    [header addSubview:sub];
    self.tableView.tableHeaderView = header;

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    footer.text = @"wechat:qwetech";
    footer.font = [UIFont systemFontOfSize:12];
    footer.textColor = [UIColor tertiaryLabelColor];
    footer.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableFooterView = footer;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return 2; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    UISwitch *sw = [[UISwitch alloc] init];
    if (ip.row == 0) {
        cell.textLabel.text = @"去除开屏广告";
        cell.detailTextLabel.text = @"启动时跳过广告页面";
        sw.on = [XYABSettingsViewController isSplashAdBlocked];
        [sw addTarget:self action:@selector(toggleSplash:) forControlEvents:UIControlEventValueChanged];
    } else {
        cell.textLabel.text = @"过滤广告商品";
        cell.detailTextLabel.text = @"隐藏搜索结果中的广告商品";
        sw.on = [XYABSettingsViewController isFeedAdFilterOn];
        [sw addTarget:self action:@selector(toggleFeedAd:) forControlEvents:UIControlEventValueChanged];
    }
    cell.accessoryView = sw;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip { return 60; }
- (void)toggleSplash:(UISwitch *)s { [XYABSettingsViewController setSplashAdBlocked:s.isOn]; }
- (void)toggleFeedAd:(UISwitch *)s { [XYABSettingsViewController setFeedAdFilterOn:s.isOn]; }
@end
