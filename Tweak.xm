#if !__LP64__

#import "Header.h"
#import <CoreMedia/CoreMedia.h>
#import <dlfcn.h>

%config(generator=MobileSubstrate)

%group mediaserverd

typedef struct HXISPCaptureStream *HXISPCaptureStreamRef;
typedef struct HXISPCaptureDevice *HXISPCaptureDeviceRef;
typedef struct OpaqueCMBaseObject *OpaqueCMBaseObjectRef;

int (*CopySupportedFormatsArray)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef);
%hookf(int, CopySupportedFormatsArray, CFAllocatorRef ref, CFMutableArrayRef *formats, HXISPCaptureStreamRef arg3, HXISPCaptureDeviceRef arg4) {
    CFMutableArrayRef refo;
    int r = %orig(ref, &refo, arg3, arg4);
    for (CFIndex i = 0; i < CFArrayGetCount(refo); ++i) {
        CFDictionaryRef iformat = (CFDictionaryRef)CFArrayGetValueAtIndex(refo, i);
        if (!CFDictionaryContainsKey(iformat, CFSTR("Experimental"))) continue;
#ifdef __DEBUG__
        logCFDictionary(0, iformat);
#endif
        BOOL modify = NO;
        CMVideoFormatDescriptionRef ref = (CMVideoFormatDescriptionRef)CFDictionaryGetValue(iformat, CFSTR("FormatDescription"));
        const FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(ref);
        if (!CFDictionaryContainsKey(iformat, CFSTR("VideoOverscannedCompanionModeIndex"))) {
            if (mediaSubType == '420v' && CMVideoFormatDescriptionGetDimensions(ref).width == 1280 && CMVideoFormatDescriptionGetDimensions(ref).height == 720) {
                int VideoMaxFrameRate = 0, VideoMaxWidth = 0, VideoMaxHeight = 0;
                getNumberValue(VideoMaxFrameRate)
                getNumberValue(VideoMaxWidth)
                getNumberValue(VideoMaxHeight)
                if (VideoMaxFrameRate == 60 && VideoMaxWidth == 2816 && VideoMaxHeight == 792)
                    modify = YES;
            }
        }
        if (modify) {
            CFMutableDictionaryRef format = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(iformat), iformat);
            CFDictionaryRemoveValue(format, CFSTR("Experimental"));
            CFStringRef values[1] = { CFSTR("AVCaptureSessionPresetHigh60") };
            CFArrayRef preset = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 1, &kCFTypeArrayCallBacks);
            CFDictionaryAddValue(format, CFSTR("AVCaptureSessionPresets"), preset);
            CFRelease(preset);
            CFArraySetValueAtIndex(refo, i, format);
        }
    }
    *formats = refo;
    return r;
}

%end

%group MG

extern "C" bool MGGetBoolAnswer(CFStringRef);
%hookf(bool, MGGetBoolAnswer, CFStringRef key) {
    return CFStringEqual(key, CFSTR("RearFacingCamera60fpsVideoCaptureCapability")) ? YES : %orig;
}

extern "C" SInt32 MGGetSInt32Answer(CFStringRef, SInt32);
%hookf(SInt32, MGGetSInt32Answer, CFStringRef key, SInt32 defautValue) {
    // back 720p60
    return CFStringEqual(key, CFSTR("0/7QNywWU4IqDcyvTv9UYQ")) ? 60 : %orig;
}

%end

%ctor {
    char *executablePathC = **_NSGetArgv();
	NSString *executablePath = [NSString stringWithUTF8String:executablePathC];
    NSString *processName = [executablePath lastPathComponent];
    if ([@"mediaserverd" isEqualToString:processName]) {
        dlopen("/System/Library/MediaCapture/H4ISP.mediacapture", RTLD_NOW);
        MSImageRef h4Ref = MSGetImageByName("/System/Library/MediaCapture/H4ISP.mediacapture");
        CopySupportedFormatsArray = (int (*)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(h4Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H4ISPCaptureStreamP18H4ISPCaptureDevice");
        %init(mediaserverd);
    } else {
        %init(MG);
    }
}

#endif