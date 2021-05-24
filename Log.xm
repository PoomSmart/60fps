#ifdef __DEBUG__

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <HBLog.h>

void logCFDictionary(int level, CFDictionaryRef dict) {
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