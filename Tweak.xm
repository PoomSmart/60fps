#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

typedef struct H4ISPCaptureStream *H4ISPCaptureStreamRef;
typedef struct H4ISPCaptureDevice *H4ISPCaptureDeviceRef;
typedef struct OpaqueCMBaseObject *OpaqueCMBaseObjectRef;

int (*CopySupportedFormatsArray)(CFAllocatorRef, CFMutableArrayRef *, H4ISPCaptureStreamRef, H4ISPCaptureDeviceRef);
%hookf(int, CopySupportedFormatsArray, CFAllocatorRef ref, CFMutableArrayRef *arg2, H4ISPCaptureStreamRef arg3, H4ISPCaptureDeviceRef arg4) {
    CFMutableArrayRef refo;
    int r = %orig(ref, &refo, arg3, arg4);
    NSMutableArray *array = (NSMutableArray *)refo;
    for (NSUInteger i = 0; i < array.count; i++) {
        NSMutableDictionary *format = [[array[i] mutableCopy] autorelease];
        NSInteger videoMaxFPS = [format[@"VideoMaxFrameRate"] integerValue];
        NSInteger videoMaxWidth = [format[@"VideoMaxWidth"] integerValue];
        NSInteger videoMaxHeight = [format[@"VideoMaxHeight"] integerValue];
        BOOL filter = format[@"VideoOverscannedCompanionModeIndex"] == nil;
        CMVideoFormatDescriptionRef ref = (CMVideoFormatDescriptionRef)format[@"FormatDescription"];
        const FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(ref);
        if (mediaSubType == '420v' && CMVideoFormatDescriptionGetDimensions(ref).width == 1280 && CMVideoFormatDescriptionGetDimensions(ref).height == 720 && videoMaxFPS == 60 && videoMaxWidth == 2816 && videoMaxHeight == 792 && filter) {
            HBLogDebug(@"##########\n\n\n60fps: Format found\n\n\n##########");
            [format removeObjectForKey:@"Experimental"];
            HBLogDebug(@"%@", format);
        }
        array[i] = format;
    }
    *arg2 = (CFMutableArrayRef)array;
    return r;
}

#define CELESTIAL "/System/Library/PrivateFrameworks/Celestial.framework/Celestial"
#define H4 "/System/Library/MediaCapture/H4ISP.mediacapture"

%ctor {
    void *h4 = dlopen(H4, RTLD_LAZY);
    if (h4) {
        MSImageRef h4Ref = MSGetImageByName(H4);
        CopySupportedFormatsArray = (int (*)(CFAllocatorRef, CFMutableArrayRef *, H4ISPCaptureStreamRef, H4ISPCaptureDeviceRef))MSFindSymbol(h4Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H4ISPCaptureStreamP18H4ISPCaptureDevice");
        %init;
    }
}
