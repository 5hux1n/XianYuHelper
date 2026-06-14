TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Runner
THEOS_PACKAGE_SCHEME = rootless
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = XianYuHelper
XianYuHelper_FILES = Tweak.xm XYHSettingsViewController.m
XianYuHelper_CFLAGS = -fobjc-arc
XianYuHelper_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
