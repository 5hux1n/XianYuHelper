# 闲鱼去广告助手

闲鱼 iOS 越狱插件，让闲鱼更清爽。

## 功能

| 功能 | 说明 |
|------|------|
| 去除开屏广告 | 冷启动时跳过广告页面，直接进入首页 |
| 去除热启动广告 | 拦截「切后台再回前台」时弹出的启动广告 |
| 过滤搜索广告 | 隐藏搜索结果中带「广告」标识的淘宝推广商品，无空白占位 |

所有功能均可在 App 内「我的 → 关于闲鱼 → 闲鱼去广告助手」中开关。

## 安装

### 方式一：从软件源安装（推荐）

添加源 `https://apt.mjh.im`，搜索「闲鱼去广告助手」。

### 方式二：DEB 包安装

从 [Releases](https://github.com/5hux1n/XianYuHelper/releases) 下载 deb，用 Sileo / Zebra 或命令行安装：

```bash
dpkg -i im.mjh.xianyuadblock_2.0_iphoneos-arm64.deb     # arm64  (Dopamine / palera1n)
dpkg -i im.mjh.xianyuadblock_2.0_iphoneos-arm64e.deb    # arm64e (RootHide)
```

### 方式三：从源码编译

```bash
git clone https://github.com/5hux1n/XianYuHelper.git
cd XianYuHelper

# rootless（Dopamine / palera1n）
THEOS=$HOME/theos make clean package FINALPACKAGE=1

# roothide（RootHide）
THEOS=$HOME/theos-roothide make clean package THEOS_PACKAGE_SCHEME=roothide
```

## 兼容性

- iOS 15.0+
- arm64（Dopamine / palera1n）与 arm64e（RootHide）分别打包

### 设置入口

闲鱼 → 我的 → 关于闲鱼 → 闲鱼去广告助手

## 项目结构

```
├── Makefile                     # 双方案构建（rootless / roothide）
├── control                      # DEB 元数据
├── XianyuAdBlock.plist          # Bundle 过滤
├── Tweak.xm                     # 核心 Hook 代码
├── XYABSettingsViewController.h
└── XYABSettingsViewController.m
```

## 实现要点

### 冷启动开屏

Hook `FMSplashModule -showSplashView`。先 `%orig` 让原始流程跑完（状态栏等初始化保持正常），
再异步调用 `-fishSplashAdDidFinish` 收尾。

### 热启动开屏

闲鱼 7.28.x 起新增的独立链路，入口不在 `FMSplashModule`，而在 **`FMHomeRefreshHelper`**：

```
FMHomeRefreshHelper.handleAppWillEnterForeground    回前台入口
  ├─ hotStartMinMinutes / lastEnterBackgroundTime   后台时长阈值（本机实测为 10 分钟）
  ├─ requestHotStartDecide:                         向服务端要决策（参数就是后台分钟数）
  ├─ handleHotStartDecideResult:backgroundMinutes:  决策回调，广告在这里出
  └─ postHotStartRefreshHomeNotification            同一函数里还有正常的首页刷新
```

`FishSplashAdConfig.disableHotStartAd` 是闲鱼自带的热启动广告开关。

**关键点：必须在 `-handleAppWillEnterForeground` 调用 `%orig` 之前把该开关置为 YES。**
App 在那一瞬间读取配置并立刻发出广告请求；若拖到 `UIApplicationDidBecomeActiveNotification`
再做（实测晚约 220 ms），请求已经发出，拦截无效。而且该开关会被服务端下发的配置重置，
所以每次回前台都要重新置位。

### 信息流广告

扫描 `UICollectionViewCell` 内文本为「广告」的 `UILabel`，命中后 swizzle
`collectionView:layout:sizeForItemAtIndexPath:` 返回 `{0, 0}`，避免留下空白占位。

## 开发提示

- `%ctor` 里**不要碰闲鱼自己的类**。dyld 初始化阶段 App 的容器路径、第三方库都未就绪，
  调用 Swift 类（如 `FishSplashAdConfig`，其初始化会走到 MMKV）会解引用空指针直接闪退。
  正确做法是把初始化推迟到 App 起来之后。
- `CydiaSubstrate` 采用**弱链接**，`%ctor` 里用 `dlsym` 判空后再 `%init`。这样即使被
  「巨魔注入器」注入到没有 Substrate 的环境，也只是插件不生效，不会让 App 打不开。
- 所有 `%hook` 收在 `%group` 里由 `%ctor` 门控 `%init`，避免生成无条件的 `_logosLocalInit` 构造器。

## License

MIT

## 联系

wechat: qwetech
