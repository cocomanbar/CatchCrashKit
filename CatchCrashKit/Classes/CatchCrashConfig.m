//
//  CatchCrashConfig.m
//  CatchCrashKit
//
//  Created by tanxl on 2022/5/7.
//

#import "CatchCrashConfig.h"

@implementation CatchCrashConfig

+ (instancetype)defaultConfig {
    CatchCrashConfig *config = [[CatchCrashConfig alloc] init];
    config.signal = CCSignal;
    config.interceptSignalHandler = true;
    config.interceptExceptionHandler = true;
    return config;
}

@end
