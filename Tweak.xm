#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

typedef struct H4ISPCaptureStream *H4ISPCaptureStreamRef;
typedef struct H4ISPCaptureDevice *H4ISPCaptureDeviceRef;
typedef struct OpaqueCMBaseObject *OpaqueCMBaseObjectRef;

/*typedef struct sCIspCameraConfig *sCIspCameraConfigRef;
typedef struct sCIspCmdChInfoGet *sCIspCmdChInfoGetRef;

int (*my_GetCameraConfig)(unsigned int, unsigned int, sCIspCameraConfig *, sCIspCmdChInfoGet *);
int (*orig_GetCameraConfig)(unsigned int, unsigned int, sCIspCameraConfig *, sCIspCmdChInfoGet *);
int hax_GetCameraConfig(unsigned int arg1, unsigned int arg2, sCIspCameraConfig *arg3, sCIspCmdChInfoGet *arg4)
{

}*/

/*int (*my_H4ISPCaptureDeviceCopyProperty)(OpaqueCMBaseObjectRef, CFStringRef const, CFAllocatorRef, CFMutableArrayRef *);
int (*orig_H4ISPCaptureDeviceCopyProperty)(OpaqueCMBaseObjectRef, CFStringRef const, CFAllocatorRef, CFMutableArrayRef *);
int hax_H4ISPCaptureDeviceCopyProperty(OpaqueCMBaseObjectRef ref, CFStringRef const key, CFAllocatorRef allocator, CFMutableArrayRef *property)
{
	CFMutableArrayRef myProperty;
	int orig = orig_H4ISPCaptureDeviceCopyProperty(ref, key, allocator, &myProperty);
	NSLog(@"%@ : %@", key, myProperty);
	CFRelease(myProperty);
	return orig;
}*/

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
		CMVideoFormatDescriptionRef ref = (CMVideoFormatDescriptionRef)format[@"FormatDescription"];
		if (CMVideoFormatDescriptionGetDimensions(ref).width == 1280 && CMVideoFormatDescriptionGetDimensions(ref).height == 720 && videoMaxFPS == 60)
			[format removeObjectForKey:@"Experimental"];
		array[i] = format;
	}
	//NSLog(@"%@", array);
	*arg2 = (CFMutableArrayRef)array;
	return r;
}

/*static NSMutableDictionary *format60fps(NSInteger nwidth, NSInteger nheight, NSInteger nmaxWidth, NSInteger nmaxHeight, float fov, NSInteger nminIntegrationTime, NSInteger nmaxIntegrationTime, float videoScaleFactor, NSUInteger index)
{
	NSMutableDictionary *format = [NSMutableDictionary dictionary];
	NSNumber *width = @(nwidth);
	NSNumber *height = @(nheight);
	NSNumber *maxWidth = @(nwidth);
	NSNumber *maxHeight = @(nheight);
	NSNumber *minIntegrationTime = @(nminIntegrationTime);
	NSNumber *maxIntegrationTime = @(nmaxIntegrationTime);
	format[@"VideoCropRect"] = @{@"Width" : width, @"Height" : height, @"X" : @0, @"Y" : @0};
	format[@"VideoFieldOfView"] = @(fov);
	format[@"VideoIsBinned"] = @1;
	format[@"VideoLowLightContextSwitchSupported"] = @0;
	format[@"VideoMaxFrameRate"] = @60;
	format[@"VideoMinFrameRate"] = @1;
	format[@"VideoMaxWidth"] = maxWidth;
	format[@"VideoMaxHeight"] = maxHeight;
	format[@"Width"] = width;
	format[@"Height"] = height;
	format[@"VideoMinIntegrationTime"] = minIntegrationTime;
	format[@"VideoMaxIntegrationTime"] = maxIntegrationTime;
	format[@"VideoRawBitDepth"] = @10;
	format[@"VideoScaleFactor"] = @(videoScaleFactor);
	format[@"PixelFormatType"] = @875704422;
	format[@"Index"] = @(index);
	return format;
}

static NSMutableArray *arrayByAdding60FPS(NSMutableArray *sensorArray)
{
	NSMutableDictionary *dictionaryOfPortTypeBack = [(NSDictionary *)sensorArray[0] mutableCopy];
	NSMutableArray *formatArray = [dictionaryOfPortTypeBack[@"SupportedFormatsArray"] mutableCopy];
	NSMutableDictionary *format = format60fps(1280, 720, 1408, 792, 48.26, 17, 1000000, 0.9090909, 6);
	if (![formatArray containsObject:format])
		[formatArray addObject:format];
	NSMutableDictionary *anotherPixelFormat = [format mutableCopy];
	anotherPixelFormat[@"PixelFormatType"] = @875704438;
	if (![formatArray containsObject:anotherPixelFormat])
		[formatArray addObject:anotherPixelFormat];
	[dictionaryOfPortTypeBack setObject:formatArray forKey:@"SupportedFormatsArray"];
	[sensorArray replaceObjectAtIndex:0 withObject:dictionaryOfPortTypeBack];
	return sensorArray;
}

CFPropertyListRef (*orig__FigVideoCaptureCopyCameraStreamInfo)();
CFPropertyListRef new__FigVideoCaptureCopyCameraStreamInfo()
{
	CFPropertyListRef sensorProperties = orig__FigVideoCaptureCopyCameraStreamInfo();
	return (CFPropertyListRef)arrayByAdding60FPS([(NSArray *)sensorProperties mutableCopy]);
}*/

#define CELESTIAL "/System/Library/PrivateFrameworks/Celestial.framework/Celestial"
#define H4 "/System/Library/MediaCapture/H4ISP.mediacapture"

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	/*void *celestial = dlopen(CELESTIAL, RTLD_LAZY);
	if (celestial != nil) {
		MSHookFunction((void *)MSFindSymbol(NULL, "_FigVideoCaptureCopyCameraStreamInfo"), (void *)new__FigVideoCaptureCopyCameraStreamInfo, (void **)&orig__FigVideoCaptureCopyCameraStreamInfo);
	}*/
	void *h4 = dlopen(H4, RTLD_LAZY);
	if (h4 != NULL) {
		MSImageRef h4Ref = MSGetImageByName(H4);		
		my_CopySupportedFormatsArray = (int (*)(CFAllocatorRef, CFMutableArrayRef *, H4ISPCaptureStreamRef, H4ISPCaptureDeviceRef))MSFindSymbol(h4Ref, "__ZL25CopySupportedFormatsArrayPK13__CFAllocatorPvP18H4ISPCaptureStreamP18H4ISPCaptureDevice");
		MSHookFunction((void *)my_CopySupportedFormatsArray, (void *)hax_CopySupportedFormatsArray, (void **)&orig_CopySupportedFormatsArray);
		//my_H4ISPCaptureDeviceCopyProperty = (int (*)(OpaqueCMBaseObjectRef, CFStringRef const, CFAllocatorRef, CFMutableArrayRef *))MSFindSymbol(h4Ref, "__ZL30H4ISPCaptureDeviceCopyPropertyP18OpaqueCMBaseObjectPK10__CFStringPK13__CFAllocatorPv");
		//MSHookFunction((void *)my_H4ISPCaptureDeviceCopyProperty, (void *)hax_H4ISPCaptureDeviceCopyProperty, (void **)&orig_H4ISPCaptureDeviceCopyProperty);
	}
	[pool drain];
}
