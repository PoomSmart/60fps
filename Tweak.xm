#import <CoreMedia/CoreMedia.h>
#import "../PS.h"

%group mediaserverd

BOOL H6 = NO;

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
        BOOL modify = NO;
        BOOL sixty = NO;
        BOOL fourk = NO;
        CMVideoFormatDescriptionRef ref = (CMVideoFormatDescriptionRef)CFDictionaryGetValue(iformat, CFSTR("FormatDescription"));
        const FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(ref);
        CFNumberRef numberRef;
        if (H6) {
            if (mediaSubType == '420v') {
                // 1080p60
                if (CMVideoFormatDescriptionGetDimensions(ref).width == 1920 && CMVideoFormatDescriptionGetDimensions(ref).height == 1080) {
                        int videoMaxFPS = 0;
                        numberRef = (CFNumberRef)CFDictionaryGetValue(iformat, CFSTR("VideoMaxFrameRate"));
                        CFNumberGetValue(numberRef, kCFNumberIntType, &videoMaxFPS);
                        if (videoMaxFPS == 60)
                            modify = sixty = YES;
                        CFRelease(numberRef);
                }
                // 4k30
                else if (CMVideoFormatDescriptionGetDimensions(ref).width == 3264 && CMVideoFormatDescriptionGetDimensions(ref).height == 2448) {
                    fourk = YES;
                    modify = YES;
                }
            }
        } else {
            if (!CFDictionaryContainsKey(iformat, CFSTR("VideoOverscannedCompanionModeIndex"))) {
                if (mediaSubType == '420v' && CMVideoFormatDescriptionGetDimensions(ref).width == 1280 && CMVideoFormatDescriptionGetDimensions(ref).height == 720) {
                    int videoMaxFPS = 0, videoMaxWidth = 0, videoMaxHeight = 0;
                    numberRef = (CFNumberRef)CFDictionaryGetValue(iformat, CFSTR("VideoMaxFrameRate"));
                    CFNumberGetValue(numberRef, kCFNumberIntType, &videoMaxFPS);
                    numberRef = (CFNumberRef)CFDictionaryGetValue(iformat, CFSTR("VideoMaxWidth"));
                    CFNumberGetValue(numberRef, kCFNumberIntType, &videoMaxWidth);
                    numberRef = (CFNumberRef)CFDictionaryGetValue(iformat, CFSTR("VideoMaxHeight"));
                    CFNumberGetValue(numberRef, kCFNumberIntType, &videoMaxHeight);
                    if (videoMaxFPS == 60 && videoMaxWidth == 2816 && videoMaxHeight == 792)
                        modify = YES;
                }
            }
        }
        if (modify) {
            CFMutableDictionaryRef format = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(iformat), iformat);
            CFDictionaryRemoveValue(format, CFSTR("Experimental"));
            if (sixty) {
                CFStringRef values[1] = { CFSTR("AVCaptureSessionPresetHigh60") };
                CFArrayRef preset = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 1, &kCFTypeArrayCallBacks);
                CFDictionaryAddValue(format, CFSTR("AVCaptureSessionPresets"), preset);
                CFRelease(preset);
            }
            if (fourk) {
                CFDictionaryRemoveValue(format, CFSTR("VideoCropRect"));
                CFDictionaryRemoveValue(format, CFSTR("SensorHDRMode"));
                CFStringRef values[1] = { CFSTR("AVCaptureSessionPreset3840x2160") };
                CFArrayRef preset = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 1, &kCFTypeArrayCallBacks);
                CFDictionaryAddValue(format, CFSTR("AVCaptureSessionPresets"), preset);
                CFRelease(preset);
                int Width = 3840, Height = 2160, SensorWidth = 4096, SensorHeight = 2304, VideoDefaultMaxFrameRate = 30;
                numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &Width);
                CFDictionarySetValue(format, CFSTR("Width"), numberRef);
                numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &Height);
                CFDictionarySetValue(format, CFSTR("Height"), numberRef);
                numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &SensorWidth);
                CFDictionarySetValue(format, CFSTR("SensorWidth"), numberRef);
                numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &SensorHeight);
                CFDictionarySetValue(format, CFSTR("SensorHeight"), numberRef);
                numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &VideoDefaultMaxFrameRate);
                CFDictionarySetValue(format, CFSTR("VideoDefaultMaxFrameRate"), numberRef);
                CMVideoFormatDescriptionRef info = NULL;
                CFDictionaryRef extensions = CMFormatDescriptionGetExtensions((CMFormatDescriptionRef)ref);
                CMVideoFormatDescriptionCreate(kCFAllocatorDefault, '420v', 3840, 2160, extensions, &info);
                CFDictionarySetValue(format, CFSTR("FormatDescription"), info);
            }
            CFArraySetValueAtIndex(refo, i, format);
        }
    }
    *formats = refo;
    return r;
}

%end

%group MG

extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
    return CFStringEqual(key, CFSTR("RearFacingCamera60fpsVideoCaptureCapability")) ? YES : %orig;
}

%end

%group MG_iPhone5s

extern "C" SInt32 MGGetSInt32Answer(CFStringRef, SInt32);
%hookf(SInt32, MGGetSInt32Answer, CFStringRef key, SInt32 defaultValue) {
    if (CFStringEqual(key, CFSTR("jBGZJ71pRJrqD8VZ6Tk2VQ"))) // 1080p60 (max FPS)
        return 60;
    if (CFStringEqual(key, CFSTR("po7g0ATDzGoVI1DO8ISmuw"))) // 4k30 (max FPS)
        return 30;
    return %orig;
}

%end

%group iPhone5s

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

%ctor {
    NSString *processName = [NSProcessInfo processInfo].processName;
    if ([@"mediaserverd" isEqualToString:processName]) {
        if (dlopen("/System/Library/MediaCapture/H6ISP.mediacapture", RTLD_LAZY) != NULL) {
            H6 = YES;
            MSImageRef h6Ref = MSGetImageByName("/System/Library/MediaCapture/H6ISP.mediacapture");
            CopySupportedFormatsArray = (int (*)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(h6Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H6ISPCaptureStreamP18H6ISPCaptureDevice");
        } else {
            dlopen("/System/Library/MediaCapture/H4ISP.mediacapture", RTLD_LAZY);
            MSImageRef h4Ref = MSGetImageByName("/System/Library/MediaCapture/H4ISP.mediacapture");
            CopySupportedFormatsArray = (int (*)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(h4Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H4ISPCaptureStreamP18H4ISPCaptureDevice");
        }
        %init(mediaserverd);
    } else {
        %init(MG);
        BOOL isiPhone5s = NO;
#if __LP64__
        isiPhone5s = YES;
#endif
        if (isiPhone5s) {
            %init(iPhone5s);
            %init(MG_iPhone5s);
        }
    }
}
