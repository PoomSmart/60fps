#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

typedef struct H4ISPCaptureStream *H4ISPCaptureStreamRef;
typedef struct H4ISPCaptureDevice *H4ISPCaptureDeviceRef;
typedef struct OpaqueCMBaseObject *OpaqueCMBaseObjectRef;

int (*my_CopySupportedFormatsArray)(CFAllocatorRef, CFMutableArrayRef *, H4ISPCaptureStreamRef, H4ISPCaptureDeviceRef);
int (*orig_CopySupportedFormatsArray)(CFAllocatorRef, CFMutableArrayRef *, H4ISPCaptureStreamRef, H4ISPCaptureDeviceRef);
int hax_CopySupportedFormatsArray(CFAllocatorRef ref, CFMutableArrayRef *arg2, H4ISPCaptureStreamRef arg3, H4ISPCaptureDeviceRef arg4)
{
	CFMutableArrayRef refo;
	int r = orig_CopySupportedFormatsArray(ref, &refo, arg3, arg4);
	NSMutableArray *array = (NSMutableArray *)refo;
	for (NSUInteger i = 0; i < array.count;  i++) {
		NSMutableDictionary *format = [array[i] mutableCopy];
		NSInteger videoMaxFPS = [format[@"VideoMaxFrameRate"] intValue];
		NSInteger videoMaxWidth = [format[@"VideoMaxWidth"] intValue];
		NSInteger videoMaxHeight = [format[@"VideoMaxHeight"] intValue];
		BOOL filter = format[@"VideoOverscannedCompanionModeIndex"] == nil;
		CMVideoFormatDescriptionRef ref = (CMVideoFormatDescriptionRef)format[@"FormatDescription"];
		const FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(ref);
		if (mediaSubType == '420v' && CMVideoFormatDescriptionGetDimensions(ref).width == 1280 && CMVideoFormatDescriptionGetDimensions(ref).height == 720 && videoMaxFPS == 60 && videoMaxWidth == 2816 && videoMaxHeight == 792 && filter)
			[format removeObjectForKey:@"Experimental"];
		array[i] = format;
	}
	*arg2 = (CFMutableArrayRef)array;
	return r;
}

#define CELESTIAL "/System/Library/PrivateFrameworks/Celestial.framework/Celestial"
#define H4 "/System/Library/MediaCapture/H4ISP.mediacapture"

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	void *h4 = dlopen(H4, RTLD_LAZY);
	if (h4 != NULL) {
		MSImageRef h4Ref = MSGetImageByName(H4);		
		my_CopySupportedFormatsArray = (int (*)(CFAllocatorRef, CFMutableArrayRef *, H4ISPCaptureStreamRef, H4ISPCaptureDeviceRef))MSFindSymbol(h4Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H4ISPCaptureStreamP18H4ISPCaptureDevice");
		MSHookFunction((void *)my_CopySupportedFormatsArray, (void *)hax_CopySupportedFormatsArray, (void **)&orig_CopySupportedFormatsArray);
	}
	[pool drain];
}
