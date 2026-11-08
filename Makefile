export TARGET  = iphone:clang:16.5:15.0
export ARCHS   = arm64 arm64e
export PACKAGE_VERSION = 0.1.0

TWEAK_NAME = floatingViewClone
floatingViewClone_FILES = $(shell find Sources -name '*.swift')
floatingViewClone_SWIFTFLAGS = -swift-version 5 -import-objc-header $(THEOS_PROJECT_DIR)/stubs/FVPrivate.h
floatingViewClone_FRAMEWORKS = UIKit Foundation QuartzCore AVFAudio ReplayKit \
	CoreImage CoreTelephony IOKit
floatingViewClone_LIBRARIES = orion
floatingViewClone_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

BUNDLE_NAME = floatingViewClonePrefs
floatingViewClonePrefs_FILES = $(shell find prefs -name '*.swift')
floatingViewClonePrefs_SWIFTFLAGS = -swift-version 5 -import-objc-header $(THEOS_PROJECT_DIR)/stubs/FVPrivate.h
floatingViewClonePrefs_FRAMEWORKS = UIKit Foundation
floatingViewClonePrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
