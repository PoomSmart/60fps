#if __LP64__

#import "Header.h"
#import <CoreMedia/CoreMedia.h>
#import <sys/utsname.h>
#import <dlfcn.h>

%config(generator=MobileSubstrate)

#define H6ISP_PATH "/System/Library/MediaCapture/H6ISP.mediacapture"
#define H6ISP_COPY_SUPPORTED_FORMATS \
    "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H6ISPCaptureStreamP18H6ISPCaptureDevice"

typedef struct HXISPCaptureStream *HXISPCaptureStreamRef;
typedef struct HXISPCaptureDevice *HXISPCaptureDeviceRef;

static BOOL isIPhone5s = NO;

static BOOL is1080p60ExperimentalFormat(CFDictionaryRef iformat) {
    if (!CFDictionaryContainsKey(iformat, CFSTR("Experimental")))
        return NO;
    CMVideoFormatDescriptionRef desc = (CMVideoFormatDescriptionRef)CFDictionaryGetValue(iformat, CFSTR("FormatDescription"));
    if (!desc)
        return NO;
    if (CMFormatDescriptionGetMediaSubType(desc) != '420v')
        return NO;
    CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(desc);
    if (dims.width != 1920 || dims.height != 1080)
        return NO;
    int VideoMaxFrameRate = 0;
    getNumberValue(VideoMaxFrameRate)
    return VideoMaxFrameRate == 60;
}

%group mediaserverd

int (*CopySupportedFormatsArray64)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef);
%hookf(int, CopySupportedFormatsArray64, CFAllocatorRef allocator, CFMutableArrayRef *formats, HXISPCaptureStreamRef stream, HXISPCaptureDeviceRef device) {
    CFMutableArrayRef refo = NULL;
    int r = %orig(allocator, &refo, stream, device);
    if (!refo) {
        *formats = refo;
        return r;
    }
    for (CFIndex i = 0; i < CFArrayGetCount(refo); ++i) {
        CFDictionaryRef iformat = (CFDictionaryRef)CFArrayGetValueAtIndex(refo, i);
        if (!is1080p60ExperimentalFormat(iformat))
            continue;
        CFMutableDictionaryRef format = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(iformat), iformat);
        CFDictionaryRemoveValue(format, CFSTR("Experimental"));
        CFDictionarySetValue(format, CFSTR("HighProfileH264Supported"), kCFBooleanTrue);
        CFStringRef values[1] = { CFSTR("AVCaptureSessionPresetHigh60") };
        CFArrayRef preset = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 1, &kCFTypeArrayCallBacks);
        CFDictionarySetValue(format, CFSTR("AVCaptureSessionPresets"), preset);
        CFRelease(preset);
#ifdef __DEBUG__
        logCFDictionary(0, format);
#endif
        CFArraySetValueAtIndex(refo, i, format);
        CFRelease(format);
    }
    *formats = refo;
    return r;
}

%end

%group MG

bool MGGetBoolAnswer(CFStringRef);
%hookf(bool, MGGetBoolAnswer, CFStringRef key) {
    if (key && CFEqual(key, CFSTR("RearFacingCamera60fpsVideoCaptureCapability")))
        return YES;
    return %orig;
}

SInt32 MGGetSInt32Answer(CFStringRef, SInt32);
%hookf(SInt32, MGGetSInt32Answer, CFStringRef key, SInt32 defaultValue) {
    if (isIPhone5s && key && CFEqual(key, CFSTR("jBGZJ71pRJrqD8VZ6Tk2VQ")))
        return 60;
    return %orig;
}

%end

%group iPhone5sEncoder

%hook AVCaptureFigVideoDevice

- (long long)maxH264VideoDimensions {
    return 4096LL | (4096LL << 32);
}

- (int)minMacroblocksForHighProfileUpTo30fps {
    return 3600;
}

- (int)minMacroblocksForHighProfileAbove30fps {
    return 1201;
}

- (BOOL)usesQuantizationScalingMatrix_H264_Steep_16_48 {
    return YES;
}

%end

%end

%group HighProfileH264

%hook FigCaptureSourceVideoFormat

- (BOOL)isHighProfileH264Supported {
    return YES;
}

%end

%end

%ctor {
    struct utsname systemInfo;
    uname(&systemInfo);
    isIPhone5s = strncmp(systemInfo.machine, "iPhone6,", 8) == 0;

    if (!isIPhone5s)
        return;

    NSString *processName = [[NSString stringWithUTF8String:**_NSGetArgv()] lastPathComponent];
    if ([processName isEqualToString:@"mediaserverd"]) {
        if (dlopen(H6ISP_PATH, RTLD_NOW)) {
            MSImageRef h6Ref = MSGetImageByName(H6ISP_PATH);
            void *sym = h6Ref ? MSFindSymbol(h6Ref, H6ISP_COPY_SUPPORTED_FORMATS) : NULL;
            if (sym)
                %init(mediaserverd, CopySupportedFormatsArray64 = sym);
        }
    } else {
        %init(MG);
    }
    %init(iPhone5sEncoder);
    %init(HighProfileH264);
}

#endif
