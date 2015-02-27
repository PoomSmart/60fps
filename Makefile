PACKAGE_VERSION = 0.0.1
GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7

include theos/makefiles/common.mk

TWEAK_NAME = 60fps7
60fps7_FILES = Tweak.xm
60fps7_FRAMEWORKS = CoreMedia

include $(THEOS_MAKE_PATH)/tweak.mk
