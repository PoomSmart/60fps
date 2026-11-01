#if !__LP64__

#import "Header.h"
#import <CoreMedia/CoreMedia.h>
#import <dlfcn.h>

%config(generator=MobileSubstrate)

#define H4ISP_PATH "/System/Library/MediaCapture/H4ISP.mediacapture"
#define H4ISP_COPY_SUPPORTED_FORMATS \
    "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H4ISPCaptureStreamP18H4ISPCaptureDevice"

typedef struct HXISPCaptureStream *HXISPCaptureStreamRef;
typedef struct HXISPCaptureDevice *HXISPCaptureDeviceRef;

static BOOL is720p60ExperimentalFormat(CFDictionaryRef iformat) {
    if (!CFDictionaryContainsKey(iformat, CFSTR("Experimental")))
        return NO;
    if (CFDictionaryContainsKey(iformat, CFSTR("VideoOverscannedCompanionModeIndex")))
        return NO;
    CMVideoFormatDescriptionRef desc = (CMVideoFormatDescriptionRef)CFDictionaryGetValue(iformat, CFSTR("FormatDescription"));
    if (!desc)
        return NO;
    if (CMFormatDescriptionGetMediaSubType(desc) != '420v')
        return NO;
    CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(desc);
    if (dims.width != 1280 || dims.height != 720)
        return NO;
    int VideoMaxFrameRate = 0, VideoMaxWidth = 0, VideoMaxHeight = 0;
    getNumberValue(VideoMaxFrameRate)
    getNumberValue(VideoMaxWidth)
    getNumberValue(VideoMaxHeight)
    return VideoMaxFrameRate == 60 && VideoMaxWidth == 2816 && VideoMaxHeight == 792;
}

%group mediaserverd

int (*CopySupportedFormatsArray)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef);
%hookf(int, CopySupportedFormatsArray, CFAllocatorRef allocator, CFMutableArrayRef *formats, HXISPCaptureStreamRef stream, HXISPCaptureDeviceRef device) {
    CFMutableArrayRef refo = NULL;
    int r = %orig(allocator, &refo, stream, device);
    if (!refo) {
        *formats = refo;
        return r;
    }
    for (CFIndex i = 0; i < CFArrayGetCount(refo); ++i) {
        CFDictionaryRef iformat = (CFDictionaryRef)CFArrayGetValueAtIndex(refo, i);
        if (!is720p60ExperimentalFormat(iformat))
            continue;
#ifdef __DEBUG__
        logCFDictionary(0, iformat);
#endif
        CFMutableDictionaryRef format = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(iformat), iformat);
        CFDictionaryRemoveValue(format, CFSTR("Experimental"));
        CFStringRef values[1] = { CFSTR("AVCaptureSessionPresetHigh60") };
        CFArrayRef preset = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 1, &kCFTypeArrayCallBacks);
        CFDictionaryAddValue(format, CFSTR("AVCaptureSessionPresets"), preset);
        CFRelease(preset);
        CFArraySetValueAtIndex(refo, i, format);
        CFRelease(format);
    }
    *formats = refo;
    return r;
}

%end

%group MGBool

bool MGGetBoolAnswer(CFStringRef);
%hookf(bool, MGGetBoolAnswer, CFStringRef key) {
    if (key && CFEqual(key, CFSTR("RearFacingCamera60fpsVideoCaptureCapability")))
        return YES;
    return %orig;
}

%end

%group MGInt

SInt32 MGGetSInt32Answer(CFStringRef, SInt32);
%hookf(SInt32, MGGetSInt32Answer, CFStringRef key, SInt32 defaultValue) {
    if (key && CFEqual(key, CFSTR("0/7QNywWU4IqDcyvTv9UYQ")))
        return 60;
    return %orig;
}

%end

%ctor {
    NSString *processName = [[NSString stringWithUTF8String:**_NSGetArgv()] lastPathComponent];
    if ([processName isEqualToString:@"mediaserverd"]) {
        dlopen(H4ISP_PATH, RTLD_NOW);
        MSImageRef h4Ref = MSGetImageByName(H4ISP_PATH);
        void *sym = h4Ref ? MSFindSymbol(h4Ref, H4ISP_COPY_SUPPORTED_FORMATS) : NULL;
        if (sym)
            %init(mediaserverd, CopySupportedFormatsArray = sym);
    } else {
        %init(MGBool);
        MSImageRef gestalt = MSGetImageByName("/usr/lib/libMobileGestalt.dylib");
        void *sint = gestalt ? MSFindSymbol(gestalt, "_MGGetSInt32Answer") : NULL;
        if (sint)
            %init(MGInt, MGGetSInt32Answer = sint);
    }
}

#endif
