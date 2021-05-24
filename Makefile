PACKAGE_VERSION = 1.0.0~b1
TARGET = iphone:clang:latest:7.0
ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 60fps
60fps_FILES = Tweak.xm Tweak64.xm Log.xm
60fps_FRAMEWORKS = CoreMedia
60fps_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
