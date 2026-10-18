# 闲鱼助手

闲鱼 iOS 插件。支持 iOS 14.0 以上。

- 去除开屏和热启动广告，过滤搜索广告，隐藏「闲鱼回收」卡片。
- 自动翻新商品、普通擦亮、领取会员经验，已完成的每日任务自动跳过。
- 买家、卖家自动好评，可分别配置评价文案和执行间隔。
- 按商品配置自动发货，支持固定内容、卡密、附加消息及图片发货凭证。
- 独立控制自动任务，查看进度、运行日志及按日期分组的记录。
- 支持配置导出、导入与清空。

## 安装与下载

当前版本：**3.2.0**。保留 [3.1.2+2](https://github.com/5hux1n/XianYuHelper/releases/tag/v3.1.2%2B2) 供降级选择。

- [插件官网](https://xianyu.goforit.si)
- [下载 3.2.0](https://github.com/5hux1n/XianYuHelper/releases/tag/v3.2.0)
- 插件源：`https://apt.mjh.im`

| 安装环境 | 下载 |
|---|---|
| Rootful（有根越狱） | [Rootful 版](https://xianyu.goforit.si/downloads/XianYuHelperRootful_3.2.0_arm64.deb) |
| Rootless | [Rootless 版](https://xianyu.goforit.si/downloads/XianYuHelper_3.2.0_arm64.deb) |
| RootHide | [RootHide 版](https://xianyu.goforit.si/downloads/XianYuHelper_3.2.0_arm64e.deb) |

按越狱环境选择安装包。RootHide 文件名中的 arm64e 表示安装方案，包内二进制为 arm64。巨魔注入使用 Rootless 包，由注入工具加载包内插件，无需单独下载 dylib。

安装或更新后，彻底退出闲鱼再打开，在「我的」页顶部点击「助手」。首次邀请关注可以跳过，是否关注不影响插件功能。

## 使用说明

所有自动功能默认关闭，按需启用。各任务可单独检查和控制；任务需要闲鱼保持前台运行。切换账号、出现安全验证或提交结果未确认时，查看运行记录后再处理。

翻新商品按原内容提交，不承诺提升曝光。清空历史记录不会清除已提交操作的防重复记录。

自动发货仍为实验功能，请先用低价值测试订单验证规则，不建议用于高价值商品。退款中及申请退款的订单不自动发货。

## 3.2.0 更新

- 修复巨魔环境注入卡死的 bug，如仍存在请降级插件版本。
- 兼容 iOS 14 及以上。

[完整更新日志](CHANGELOG.md) · [反馈入口](https://pingme.pm/xianyu)
