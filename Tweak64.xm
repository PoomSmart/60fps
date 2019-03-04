#if __LP64__

#import <CoreMedia/CoreMedia.h>
#import <sys/utsname.h>
#import "Header.h"

%config(generator=MobileSubstrate)

%group mediaserverd

int MajorVer = 0;

typedef struct HXISPCaptureStream *HXISPCaptureStreamRef;
typedef struct HXISPCaptureDevice *HXISPCaptureDeviceRef;
typedef struct OpaqueCMBaseObject *OpaqueCMBaseObjectRef;

int (*CopySupportedFormatsArray64)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef);
%hookf(int, CopySupportedFormatsArray64, CFAllocatorRef ref, CFMutableArrayRef *formats, HXISPCaptureStreamRef arg3, HXISPCaptureDeviceRef arg4) {
    CFMutableArrayRef refo;
    int r = %orig(ref, &refo, arg3, arg4);
    BOOL found_fourk_se = NO;
    CFDictionaryRef fourk_60_se = NULL;
    for (CFIndex i = 0; i < CFArrayGetCount(refo); ++i) {
        CFDictionaryRef iformat = (CFDictionaryRef)CFArrayGetValueAtIndex(refo, i);
        BOOL experimental = CFDictionaryContainsKey(iformat, CFSTR("Experimental"));
        if ((MajorVer == 6 || found_fourk_se) && !experimental) continue;
        BOOL modify = NO, sixty = NO, fourk = NO, fourk_hack = NO;
        HBLogDebug(@"Format %ld", i);
        int Width = 0, Height = 0, SensorWidth = 0, SensorHeight = 0, VideoDefaultMaxFrameRate = 0;
        if (MajorVer == 8) {
            // 4k30 -> 4k60
            getNumberValue(SensorWidth)
            getNumberValue(SensorHeight)
            if (SensorWidth == 4096 && SensorHeight == 2304 && i == 11)
                modify = found_fourk_se = YES;
        }
        else if (MajorVer == 6) {
            CMVideoFormatDescriptionRef ref = (CMVideoFormatDescriptionRef)CFDictionaryGetValue(iformat, CFSTR("FormatDescription"));
            const FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(ref);
            if (mediaSubType == '420v') {
                // 1080p60
                if (CMVideoFormatDescriptionGetDimensions(ref).width == 1920 && CMVideoFormatDescriptionGetDimensions(ref).height == 1080) {
                        int VideoMaxFrameRate = 0;
                        getNumberValue(VideoMaxFrameRate)
                        if (VideoMaxFrameRate == 60)
                            modify = sixty = YES;
                }
                // 4k30
                else if (CMVideoFormatDescriptionGetDimensions(ref).width == 3264 && CMVideoFormatDescriptionGetDimensions(ref).height == 2448)
                    modify = fourk = fourk_hack = YES;
            }
        }
        if (modify) {
            CFNumberRef ref;
            CFMutableDictionaryRef format = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(iformat), iformat);
            HBLogDebug(@"Modify format %ld", i);
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
            }
            if (found_fourk_se) {
                SensorWidth = 4224;
                SensorHeight = 2376;
                int VideoDefaultMinFrameRate = 60;
                VideoDefaultMaxFrameRate = 60;
                int VideoMaxFrameRate = 60;
                setNumberValue(SensorWidth)
                setNumberValue(SensorHeight)
                setNumberValue(VideoMaxFrameRate)
                setNumberValue(VideoDefaultMinFrameRate)
                setNumberValue(VideoDefaultMaxFrameRate)
                fourk_60_se = format;
            }
            if (fourk_hack) {
                Width = 3840;
                Height = 2160;
                SensorWidth = 4096;
                SensorHeight = 2304;
                VideoDefaultMaxFrameRate = 30;
                setNumberValue(Width)
                setNumberValue(Height)
                setNumberValue(SensorWidth)
                setNumberValue(SensorHeight)
                setNumberValue(VideoDefaultMaxFrameRate)
                CMVideoFormatDescriptionRef info = NULL;
                CFDictionaryRef extensions = CMFormatDescriptionGetExtensions((CMFormatDescriptionRef)ref);
                CMVideoFormatDescriptionCreate(kCFAllocatorDefault, '420v', 3840, 2160, extensions, &info);
                CFDictionarySetValue(format, CFSTR("FormatDescription"), info);
            }
            HBLogDebug(@"Format %ld modified", i);
#if DEBUG
            logCFDictionary(0, format);
#endif
            if (fourk_60_se == NULL)
                CFArraySetValueAtIndex(refo, i, format);
        }
    }
    if (fourk_60_se != NULL)
        CFArrayAppendValue(refo, fourk_60_se);
    *formats = refo;
    return r;
}

%end

%group MG

extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
    if (CFStringEqual(key, CFSTR("RearFacingCamera60fpsVideoCaptureCapability")))
        return YES;
    if (MajorVer == 8 && CFStringEqual(key, CFSTR("g/MkWm2Ac6+TLNBgtBGxsg"))) // HEVC
        return YES;
    return %orig;
}

extern "C" SInt32 MGGetSInt32Answer(CFStringRef, SInt32);
%hookf(SInt32, MGGetSInt32Answer, CFStringRef key, SInt32 defaultValue) {
    if (MajorVer == 6 && CFStringEqual(key, CFSTR("jBGZJ71pRJrqD8VZ6Tk2VQ"))) // 1080p60 (max FPS)
        return 60;
    if (CFStringEqual(key, CFSTR("po7g0ATDzGoVI1DO8ISmuw"))) // 4k30/60 (max FPS)
        return MajorVer == 8 ? 60 : 30;
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

%group iPhoneSE

%hook AVCaptureFigVideoDevice

- (BOOL)isHEVCSupported {
    return YES;
}

- (BOOL)isHEVCPreferred {
    return YES;
}

%end

%end

%ctor {
    struct utsname systemInfo;
    uname(&systemInfo);
    if (strncmp("iPhone8,3", systemInfo.machine, 9) == 0 || strncmp("iPhone8,4", systemInfo.machine, 9) == 0)
        MajorVer = 8;
    else if (strncmp("iPhone6", systemInfo.machine, 7) == 0)
        MajorVer = 6;
    NSString *processName = [NSProcessInfo processInfo].processName;
    if ([@"mediaserverd" isEqualToString:processName]) {
        if (dlopen("/System/Library/MediaCapture/H6ISP.mediacapture", RTLD_LAZY) != NULL) {
            MSImageRef h6Ref = MSGetImageByName("/System/Library/MediaCapture/H6ISP.mediacapture");
            CopySupportedFormatsArray64 = (int (*)(CFAllocatorRef, CFMutableArrayRef *, HXISPCaptureStreamRef, HXISPCaptureDeviceRef))MSFindSymbol(h6Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H6ISPCaptureStreamP18H6ISPCaptureDevice");
        }
        %init(mediaserverd);
    } else {
        if (MajorVer == 8) {
            %init(iPhoneSE);
        } else {
            %init(iPhone5s);
        }
        %init(MG);
    }
}

#endif