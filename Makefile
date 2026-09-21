TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Runner

FINALPACKAGE = 1
VERSION = 2.0
BASE_PACKAGE = im.mjh.xianyuadblock

# rootless（Dopamine/palera1n，/var/jb）：  THEOS=~/theos            make package
# roothide（RootHide，无前缀）        ：  THEOS=~/theos-roothide   make package THEOS_PACKAGE_SCHEME=roothide
THEOS_PACKAGE_SCHEME ?= rootless

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
JBROOT_PREFIX :=
else
JBROOT_PREFIX := /var/jb
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = XianyuAdBlock
XianyuAdBlock_FILES = Tweak.xm XYABSettingsViewController.m
XianyuAdBlock_CFLAGS = -fobjc-arc
XianyuAdBlock_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

# CydiaSubstrate 一律弱链接：
# 工程可能被「巨魔注入器」注入到 Runner.app/Frameworks/，那里没有 .jbroot，
# 强链接会在 dyld 阶段解析失败直接崩。弱链接 + %ctor 里的 dlsym 判空兜底。
XianyuAdBlock_LDFLAGS += -Wl,-weak_framework,CydiaSubstrate

# roothide 方案 theos 不会自动加 rpath，而 hook 代码需要 CydiaSubstrate。
# 缺 rpath → 弱符号解析成 NULL → 若没判空就会跳到地址 0 → 闲鱼启动即闪退。
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
XianyuAdBlock_LDFLAGS += -Wl,-rpath,@loader_path/.jbroot/Library/Frameworks \
                        -Wl,-rpath,@loader_path/.jbroot/usr/lib
endif

before-package::
	@# 版本号统一从 Makefile 注入，避免 control 与代码里的版本号走偏
	@sed -i '' 's/^Version: .*/Version: $(VERSION)/' $(THEOS_STAGING_DIR)/DEBIAN/control 2>/dev/null || true
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
	@# roothide 变体包名自洽：否则 dpkg 覆盖安装会报
	@# "trying to overwrite ... which is also in package im.mjh.xianyuadblock.roothide"
	@sed -i '' 's/^Package: .*/Package: $(BASE_PACKAGE).roothide/' $(THEOS_STAGING_DIR)/DEBIAN/control 2>/dev/null || true
endif

after-install::
	install.exec "killall -9 Runner" || true
