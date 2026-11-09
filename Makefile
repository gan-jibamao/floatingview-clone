export TARGET  = iphone:clang:16.5:15.0
export ARCHS   = arm64 arm64e
export PACKAGE_VERSION = 0.1.1

TWEAK_NAME = floatingViewClone
floatingViewClone_FILES = $(shell find Sources Shared -name '*.swift')
floatingViewClone_SWIFTFLAGS = -swift-version 5 -import-objc-header $(THEOS_PROJECT_DIR)/stubs/FVPrivate.h
floatingViewClone_FRAMEWORKS = UIKit Foundation QuartzCore AVFAudio ReplayKit \
	CoreImage CoreTelephony IOKit Orion
floatingViewClone_PRIVATE_FRAMEWORKS = FrontBoard SpringBoard SpringBoardHome \
	BackBoardServices DoNotDisturb BannerKit UserNotificationsUIKit
floatingViewClone_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

BUNDLE_NAME = floatingViewClonePrefs
# 设置 bundle 不能链接主 dylib，偏好模型要自己带一份
floatingViewClonePrefs_FILES = $(shell find prefs Shared -name '*.swift') \
	Sources/Prefs/FVPrefsKeys.swift Sources/Prefs/FVPrefsStore.swift \
	Sources/Support/FVLog.swift Sources/Tools/FVToolAction.swift \
	Sources/Support/FVAppHelper.swift Sources/Core/FVFileManager.swift
floatingViewClonePrefs_SWIFTFLAGS = -swift-version 5 -import-objc-header $(THEOS_PROJECT_DIR)/stubs/FVPrivate.h
floatingViewClonePrefs_FRAMEWORKS = UIKit Foundation
floatingViewClonePrefs_PRIVATE_FRAMEWORKS = Preferences
floatingViewClonePrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
