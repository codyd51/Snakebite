ARCHS = armv7 arm64
GO_EASY_ON_ME=1
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = Snakebite
Snakebite_FILES = Tweak.xm
Snakebite_FILES += $(wildcard *.mm)
Snakebite_FRAMEWORKS = UIKit
Snakebite_FRAMEWORKS += CoreGraphics
Snakebite_FRAMEWORKS += QuartzCore
Snakebite_FRAMEWORKS += CoreImage
Snakebite_PRIVATE_FRAMEWORKS = SpringBoardServices
Snakebite_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
