#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CatchCrashConfig.h"
#import "CatchCrashIntercepter.h"
#import "CatchCrashKit.h"

FOUNDATION_EXPORT double CatchCrashKitVersionNumber;
FOUNDATION_EXPORT const unsigned char CatchCrashKitVersionString[];

