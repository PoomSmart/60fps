#ifdef __DEBUG__

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <HBLog.h>

void logCFDictionary(int level, CFDictionaryRef dict) {
    (void)level;
    HBLogDebug(@"%@", dict);
}

#endif
