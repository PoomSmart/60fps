#ifndef _60FPS_H_
#define _60FPS_H_

#import "../PSHeader/Misc.h"
#import <CoreFoundation/CoreFoundation.h>

FOUNDATION_EXPORT char ***_NSGetArgv();

void logCFDictionary(int level, CFDictionaryRef dict);

#define getNumberValue(variable) \
    if (CFDictionaryContainsKey(iformat, CFSTR(# variable))) \
        CFNumberGetValue((CFNumberRef)CFDictionaryGetValue(iformat, CFSTR(# variable)), kCFNumberIntType, &variable);

#define setNumberValue(variable) \
    CFNumberRef ref ## variable = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &variable); \
    CFDictionarySetValue(format, CFSTR(# variable), ref ## variable); \
    if (CFGetTypeID(ref ## variable) == CFNumberGetTypeID()) CFRelease(ref ## variable);

#endif