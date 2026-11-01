#ifndef _60FPS_H_
#define _60FPS_H_

#import <PSHeader/Misc.h>

FOUNDATION_EXPORT char ***_NSGetArgv(void);

void logCFDictionary(int level, CFDictionaryRef dict);

@interface AVCaptureFigVideoDevice : NSObject
- (long long)maxH264VideoDimensions;
- (int)minMacroblocksForHighProfileUpTo30fps;
- (int)minMacroblocksForHighProfileAbove30fps;
- (BOOL)usesQuantizationScalingMatrix_H264_Steep_16_48;
@end

@interface FigCaptureSourceVideoFormat : NSObject
- (BOOL)isHighProfileH264Supported;
@end

#define getNumberValue(variable) \
    if (CFDictionaryContainsKey(iformat, CFSTR(#variable))) \
        CFNumberGetValue((CFNumberRef)CFDictionaryGetValue(iformat, CFSTR(#variable)), kCFNumberIntType, &variable);

#endif
