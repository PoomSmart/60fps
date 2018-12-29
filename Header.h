#import "../PS.h"

#define getNumberValue(variable) \
    if (CFDictionaryContainsKey(iformat, CFSTR(# variable))) \
        CFNumberGetValue((CFNumberRef)CFDictionaryGetValue(iformat, CFSTR(# variable)), kCFNumberIntType, &variable);

#define setNumberValue(variable) \
    CFNumberRef ref ## variable = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &variable); \
    CFDictionarySetValue(format, CFSTR(# variable), ref ## variable); \
    if (CFGetTypeID(ref ## variable) == CFNumberGetTypeID()) CFRelease(ref ## variable);

#if DEBUG

static void logCFDictionary(int level, CFDictionaryRef dict) {
    CFIndex size = CFDictionaryGetCount(dict);
    CFTypeRef *keysTypeRef = (CFTypeRef *)malloc(size * sizeof(CFTypeRef));
    CFTypeRef *valuesTypeRef = (CFTypeRef *)malloc(size * sizeof(CFTypeRef));
    CFDictionaryGetKeysAndValues(dict, (const void **)keysTypeRef, (const void **)valuesTypeRef);
    const void **keys = (const void **)keysTypeRef;
    const void **values = (const void **)valuesTypeRef;
    for (int i = 0; i < size; ++i) {
        if (CFGetTypeID(values[i]) == CFDictionaryGetTypeID()) {
            HBLogDebug([NSString stringWithFormat:@"%%%ds%@ : ", level * 2, keys[i]], " ");
            logCFDictionary(level + 1, (CFDictionaryRef)values[i]);
        } else
            HBLogDebug([NSString stringWithFormat:@"%%%ds%@ : %@", level * 2, keys[i], values[i]], " ");
    }
    free(keys);
    free(values);
}

#endif