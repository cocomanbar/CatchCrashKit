//
//  CatchCrashConfig.h
//  CatchCrashKit
//
//  Created by tanxl on 2022/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CCSig){
    CCSigabrt = 1 << 0, // 注册程序由于abort()函数调用发生的程序中止信号
    CCSigill  = 1 << 1, // 注册程序由于非法指令产生的程序中止信号
    CCSigsegv = 1 << 2, // 注册程序由于无效内存的引用导致的程序中止信号
    CCSigfpe  = 1 << 3, // 注册程序由于浮点数异常导致的程序中止信号
    CCSigbus  = 1 << 4, // 注册程序由于内存地址未对齐导致的程序中止信号
    CCSigpipe = 1 << 5, // 程序通过端口发送消息失败导致的程序中止信号
    
    CCSignal  = ~0UL, // 全部注册
};

@protocol CatchCrashProtocol <NSObject>

@optional

/**
 *  注册成功时回调
 */
- (void)catchCrashIntercepterRegisted;

/**
 *  关闭监听回调
 */
- (void)catchCrashIntercepterClosed;

/**
 *  发生异常时回调
 */
- (void)catchCrashIntercepterForException:(NSException * _Nonnull)exception isFromSignal:(BOOL)isFromSignal;

@end

@interface CatchCrashConfig : NSObject

/// 内核异常拦截，默认 true
@property (nonatomic, assign) BOOL interceptSignalHandler;

/// objective-c 异常拦截，默认 true
@property (nonatomic, assign) BOOL interceptExceptionHandler;

/// 内核异常类型，默认 CCSignal
@property (nonatomic, assign) CCSig signal;

/// TODO：内核异常报错时保活，不建议开启，默认 false
/// iOS/OSX 在被抛出异常后，被认为是不可恢复的，如果我们强行恢复 Runloop，整个 App 的不确定性将会更大，crash 的部分可能会再次发生；
/// 内核抛出的异常一般都是较严重的底层硬件问题，如果这类问题不及时停止程序运行，可能会进一步影响整个系统的运行，乃至损坏硬件；
@property (nonatomic, assign) BOOL keepLiveWhenSignalCrash;

/// TODO：objective-c 运行异常保活，不建议开启，默认 false
/// 如果未开启内核异常拦截，最终依然会传递到封装的Exception
/// 执意开启异常保活，可能会对设备造成不可预估的后果
@property (nonatomic, assign) BOOL keepLiveWhenExceptionCrash;

/// CC Delegate
@property (nonatomic, weak) id<CatchCrashProtocol> delegate;


/**
 *  默认初始化
 */
+ (instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END
