ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = Snakebite
Snakebite_FILES = SnakebiteListController.mm
Snakebite_INSTALL_PATH = /Library/PreferenceBundles
Snakebite_FRAMEWORKS = UIKit
Snakebite_PRIVATE_FRAMEWORKS = Preferences
Snakebite_CFLAGS = -fobjc-arc
Snakebite_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Snakebite.plist$(ECHO_END)
