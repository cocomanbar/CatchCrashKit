//
//  CatchCrashIntercepter.h
//  CatchCrashKit
//
//  Created by tanxl on 2022/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CatchCrashConfig;

@interface CatchCrashIntercepter : NSObject

/**
 *  开始拦截监控
 *
 *  注意：由于 Xcode 默认会开启 debug executable，它会在我们捕获这些异常信号之前拦截掉
 *  因此做这个测试需要手动将 debug executable 功能关闭，或者不在 Xcode 连接调试下进行测试。
 */
+ (void)startWithConfig:(CatchCrashConfig * _Nonnull)config;

/**
 *  关闭拦截监控
 */
+ (void)closeIntercepter;

@end

NS_ASSUME_NONNULL_END

