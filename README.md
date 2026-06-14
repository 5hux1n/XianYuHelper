# 咸鱼助手

闲鱼 iOS 越狱插件，让闲鱼更清爽。

## 功能

| 功能 | 说明 |
|------|------|
| 去除开屏广告 | 启动时跳过广告页面，直接进入首页 |
| 过滤搜索广告 | 隐藏搜索结果中带「广告」标识的淘宝推广商品，无空白占位 |

所有功能均可在 App 内「我的 → 关于闲鱼 → 咸鱼助手」中开关。

## 截图

> TODO

## 安装

### 方式一：DEB 包安装

从 [Releases](https://github.com/junhong/xianyuhelper/releases) 下载最新 deb，用 Sileo/Zebra 或命令行安装：

```bash
dpkg -i im.mjh.xianyuhelper_1.0.0_iphoneos-arm64.deb
```

### 方式二：从源码编译

```bash
git clone https://github.com/junhong/xianyuhelper.git
cd xianyuhelper
make package FINALPACKAGE=1
```

## 兼容性
 
- iOS 15.0+

### 设置入口

闲鱼app - 我的 - 关于 - 咸鱼助手 

## 项目结构

```
├── Makefile
├── control              # DEB 元数据
├── XianYuHelper.plist   # Bundle 过滤
├── Tweak.xm             # 核心 Hook 代码
├── XYHSettingsViewController.h
├── XYHSettingsViewController.m
└── layout/              # layout 资源 (如有)
```

## License

MIT

## 联系

wechat: qwetech
