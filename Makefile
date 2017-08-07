PACKAGE_VERSION = 0.0.3
TARGET = iphone:clang:latest:9.0:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 60fps
60fps_FILES = Tweak.xm
60fps_FRAMEWORKS = CoreMedia

include $(THEOS_MAKE_PATH)/tweak.mk
