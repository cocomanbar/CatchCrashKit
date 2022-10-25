//
//  CCAppDelegate.m
//  CatchCrashKit
//
//  Created by tanxl on 05/07/2022.
//  Copyright (c) 2022 tanxl. All rights reserved.
//

#import "CCAppDelegate.h"
#import <CatchCrashKit/CatchCrashKit.h>

@interface CCAppDelegate ()
<CatchCrashProtocol>

@end


/**
 *  Crash优化与建议
 *  https://www.jianshu.com/p/71bc3c140555
 */
@implementation CCAppDelegate

- (void)catchCrashIntercepterForException:(NSException * _Nonnull)exception isFromSignal:(BOOL)isFromSignal {
    NSLog(@"捕获到一个异常~ name：%@", exception.name);
    
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@", reason, name];
    
    NSString *logPath=[NSString stringWithFormat:@"%@/Documents/error.log",NSHomeDirectory()];
    [exceptionInfo writeToFile:logPath  atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)catchCrashIntercepterRegisted {
    NSLog(@"自己的注册成功~，可以选择在这里注册bugly~");
}

- (void)catchCrashIntercepterClosed {
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // 注册一个模拟第三方的应用
    [self registerUncaughtExceptionHandler];
    [self registerUncaughtSignalHandler];
    
    // 初始化自己的业务捕抓器
    CatchCrashConfig *config = [CatchCrashConfig defaultConfig];
    config.delegate = self;
    [CatchCrashIntercepter startWithConfig:config];
    
    return YES;
}

/**
 *  模仿bugly注册
 */
- (void)registerUncaughtExceptionHandler {
    
    NSSetUncaughtExceptionHandler(&BuglyUncaughtExceptionHandler);
}

static void BuglyUncaughtExceptionHandler(NSException *exception) {
    
    // 异常原因
    NSString *reason = [exception reason];
    NSLog(@"原始的caught：%@", reason);
    
    [exception raise];
}

- (void)registerUncaughtSignalHandler {
    signal(SIGABRT, SignalHandler);
}

void SignalHandler(int signal){
    NSLog(@"SignalHandler");
    
    // 源处理
    kill(getpid(), SIGKILL);
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
