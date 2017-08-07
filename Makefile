PACKAGE_VERSION = 0.0.4
TARGET = iphone:clang:latest:9.0:7.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 60fps
60fps_FILES = Tweak.xm
60fps_FRAMEWORKS = CoreMedia
60fps_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
