# 闲鱼去广告助手

闲鱼 iOS 越狱插件，让闲鱼更清爽。

## 功能

| 功能 | 说明 |
|------|------|
| 去除开屏广告 | 冷启动时跳过广告页，直接进首页 |
| 去除热启动广告 | 切后台再回前台时不再弹出启动广告 |
| 过滤搜索广告 | 隐藏搜索结果中带「广告」标识的淘宝推广商品，不留空白占位 |

三项都能单独开关：闲鱼 → 我的 → 关于闲鱼 → 闲鱼去广告助手。

## 安装

### 从软件源安装（推荐）

添加源 `https://apt.mjh.im`，搜索「闲鱼去广告助手」。

### 安装 deb

从 [Releases](https://github.com/5hux1n/XianYuHelper/releases) 下载，用 Sileo / Zebra 或命令行安装：

| 越狱环境 | 安装包 |
|---|---|
| Dopamine / palera1n | `im.mjh.xianyuadblock_2.0_iphoneos-arm64.deb` |
| RootHide | `im.mjh.xianyuadblock_2.0_iphoneos-arm64e.deb` |

### 从源码编译

```bash
git clone https://github.com/5hux1n/XianYuHelper.git
cd XianYuHelper

# Dopamine / palera1n
THEOS=$HOME/theos make clean package FINALPACKAGE=1

# RootHide
THEOS=$HOME/theos-roothide make clean package THEOS_PACKAGE_SCHEME=roothide
```

## 兼容性

- iOS 15.0+
- arm64 与 arm64e 分开打包，按自己的越狱环境选

## 更新日志

### 2.0

1、新增拦截「切后台再回前台」时弹出的启动广告
2、更名为「闲鱼去广告助手」，包名同步变更（旧版会被替换）

### 1.0.0

去除开屏广告，过滤搜索结果中的淘宝广告商品

## License

MIT

## 联系

wechat: qwetech
