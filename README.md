# 闲鱼助手

[官网](https://xianyu.goforit.si/) · [插件源](https://apt.mjh.im) · [下载 3.1.0](https://github.com/5hux1n/XianYuHelper/releases/tag/v3.1.0)

闲鱼 iOS 越狱插件，提供广告与页面净化、自动好评与商品任务、虚拟商品交付、配置迁移，以及任务控制和商品运行记录。

## 功能说明

- 去除冷启动开屏广告与热启动广告。
- 过滤搜索结果中的淘宝广告商品。
- 隐藏「我的」页面的「闲鱼回收」卡片，各项净化可独立开关。
- 打开闲鱼后按开关自动翻新在售商品，今日已完成的商品跳过。
- 检查并领取可领取的会员经验，已领取时跳过。
- 自动执行免费普通擦亮，今日已擦亮时跳过，默认关闭。
- 卖家、买家自动好评，评价文案与执行间隔可分别设置。
- 按商品配置自动发货，支持固定文本、卡密与接口交付。
- 支持配置导出、导入与清空，配置可经加密文件或剪贴板迁移。
- 首次进入助手可自愿关注开发者，跳过或关注失败都不影响功能。
- 翻新商品、会员经验、普通擦亮分别设独立任务区，包含本组开关、单独检查、状态与记录。
- 显示任务总数、当前数量、成功、失败及跳过数量。
- 支持暂停、继续、终止、重新开始和重试可重试的失败商品。
- 按商品短标题查看运行记录，支持成功、失败、跳过筛选、日期分组、清空历史和分页浏览。
- 近期日志固定高度并可独立滚动。
- 「我的」页顶部提供助手入口，上滑后跟随原生菜单切换。
- 擦亮与经验领取显示当日状态，历史记录支持日期分组和一键清空。
- 设置底部显示版本、插件源及官网。

## 使用

在闲鱼「我的」页顶部，点击「帮助与客服」左侧的「助手」。自动功能默认关闭，按需开启；可点击「立即检查」手动运行。

自动功能支持不同账号的商品页面。遇到闲鱼安全验证时停止任务，完成验证后可点击「立即检查」。

翻新商品保留商品内容，提交前后核对详情；暂不处理租赁、多规格等特殊商品。暂停会等待当前商品完成；提交结果不明的商品不会重复提交。完整记录在「商品运行记录」中查看。

## 安装

支持 iOS 15.0 以上，需 Rootless 或 RootHide 越狱环境并已安装闲鱼。

在 Sileo / Zebra 等包管理器添加 `https://apt.mjh.im`，搜索「闲鱼助手」；也可从官网或 [Releases](https://github.com/5hux1n/XianYuHelper/releases) 下载对应 DEB。

| 越狱环境 | 安装包 |
|---|---|
| Rootless（Dopamine / palera1n） | `im.mjh.xianyuadblock_3.1.0_iphoneos-arm64.deb` |
| RootHide | `im.mjh.xianyuadblock.roothide_3.1.0_iphoneos-arm64e.deb` |

更新时安装同环境的新版包，并彻底结束后重新打开闲鱼。

## 更新日志

### 3.1.0

1、新增卖家、买家自动好评，可分别设置评价文案和执行间隔。
2、新增虚拟商品交付：按商品配置自动发货，支持卡密导入与交付记录。
3、新增配置导出、导入与清空，配置可经加密文件或剪贴板迁移。
4、翻新商品、会员经验、普通擦亮改为独立任务，可分别检查、暂停和查看记录。
5、自动任务可分别设置执行间隔。

历史版本见 [Releases](https://github.com/5hux1n/XianYuHelper/releases)。

## 作者与项目

- 作者：junhong
- 仓库：https://github.com/5hux1n/XianYuHelper
- 官网：https://xianyu.goforit.si/
- 插件源：https://apt.mjh.im

## 直接下载 v3.1.0

- [im.mjh.xianyuadblock.roothide_3.1.0_iphoneos-arm64e.deb](https://github.com/5hux1n/XianYuHelper/releases/download/v3.1.0/im.mjh.xianyuadblock.roothide_3.1.0_iphoneos-arm64e.deb)
- [im.mjh.xianyuadblock_3.1.0_iphoneos-arm64.deb](https://github.com/5hux1n/XianYuHelper/releases/download/v3.1.0/im.mjh.xianyuadblock_3.1.0_iphoneos-arm64.deb)

[历史版本下载](https://github.com/5hux1n/XianYuHelper/releases)
