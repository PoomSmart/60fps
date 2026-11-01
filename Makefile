TARGET = iphone:clang:14.5:7.0
ARCHS = armv7 arm64
export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 60fps
$(TWEAK_NAME)_FILES = Tweak.x Tweak64.x Log.x
$(TWEAK_NAME)_FRAMEWORKS = CoreMedia
$(TWEAK_NAME)_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
