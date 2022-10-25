//
//  CatchCrashIntercepter.m
//  CatchCrashKit
//
//  Created by tanxl on 2022/5/7.
//

#import "CatchCrashIntercepter.h"
#import "CatchCrashConfig.h"

/// Exception handler
static NSUncaughtExceptionHandler *_previousUncaughtExceptionHandler;

NSString *const CatchCrashSignalName = @"signal";
NSString *const CatchCrashSignalReason = @"catch a signal error crash from deep OS.";
NSString *const CatchCrashSignalCode = @"signalcode";

@interface CatchCrashIntercepter ()

@property (nonatomic, assign) BOOL dismissed;

@property (nonatomic, strong) CatchCrashConfig *config;

@end

@implementation CatchCrashIntercepter

+ (instancetype)shared{
    static CatchCrashIntercepter *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[CatchCrashIntercepter alloc] init];
    });
    return _instance;
}

+ (void)startWithConfig:(CatchCrashConfig * _Nonnull)config {
    [[CatchCrashIntercepter shared] setConfig:config];
    
    if (config.interceptExceptionHandler) {
        registerUncaughtExceptionHandler();
    }
    if (config.interceptSignalHandler) {
        registerUncaughtSignalHandler(config.signal);
    }
    if (config.interceptExceptionHandler || config.interceptSignalHandler) {
        if ([config.delegate respondsToSelector:@selector(catchCrashIntercepterRegisted)]) {
            [config.delegate catchCrashIntercepterRegisted];
        }
    }
}

+ (void)closeIntercepter {
    
    CatchCrashConfig *config = [[CatchCrashIntercepter shared] config];
    if (config.interceptExceptionHandler) {
        if (_previousUncaughtExceptionHandler) {
            NSSetUncaughtExceptionHandler(_previousUncaughtExceptionHandler);
        }
    }
    if (config.interceptSignalHandler) {
        int fatalSignalsCount = cc_fatalSignalsCount();
        const int* fatalSignals = cc_fatalSignalsArray();
        
        for(int i = 0; i < fatalSignalsCount; i++){
            if (config.signal & fatalSignals[i]) {
                sigaction(fatalSignals[i], &previous_sa_sigactions[i], NULL);
            }
        }
    }
    if (config.interceptExceptionHandler || config.interceptSignalHandler) {
        if ([config.delegate respondsToSelector:@selector(catchCrashIntercepterClosed)]) {
            [config.delegate catchCrashIntercepterClosed];
        }
    }
}

/**
 *  处理Exception流程
 */
- (void)uncaughtExceptionHandler:(NSException *)exception {
    
    if ([self.config.delegate respondsToSelector:@selector(catchCrashIntercepterForException:isFromSignal:)]) {
        [self.config.delegate catchCrashIntercepterForException:exception isFromSignal:false];
    }
}

- (void)uncaughtSignalHandler:(int)signal info:(siginfo_t *)info context:(void *)context {
    
    NSDictionary *userInfo = @{CatchCrashSignalCode: [@(signal) stringValue]};
    NSException *exception = [NSException exceptionWithName:CatchCrashSignalName reason:CatchCrashSignalReason userInfo:userInfo];
    if ([self.config.delegate respondsToSelector:@selector(catchCrashIntercepterForException:isFromSignal:)]) {
        [self.config.delegate catchCrashIntercepterForException:exception isFromSignal:true];
    }
}

/**
 *  注册一个己方的ExceptionHandler监听器
 */
static void _UncaughtExceptionHandler(NSException *exception) {
    
    // 执行收集流程
    [[CatchCrashIntercepter shared] uncaughtExceptionHandler:exception];
        
    // 执行原来注册
    if (_previousUncaughtExceptionHandler) {
        _previousUncaughtExceptionHandler(exception);
    } else {
        // 源处理
        [exception raise];
    }
}

static void registerUncaughtExceptionHandler(void) {
    
    _previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&_UncaughtExceptionHandler);
}

/**
 *  注册一个己方的SignalHandler监听器
 */
static void _UncaughtSignalHandler(int signal, siginfo_t *info, void *context) {
    
    // 执行收集流程
    [[CatchCrashIntercepter shared] uncaughtSignalHandler:signal info:info context:context];
    
    // 执行原来注册
    int fatalSignalsCount = cc_fatalSignalsCount();
    const int* fatalSignals = cc_fatalSignalsArray();
    
    for(int i = 0; i < fatalSignalsCount; i++){
        if (signal == fatalSignals[i]) {
            // sa_handler和sa_sigaction都是信号处理函数的指针，一次只能选择两者中的一个执行，优先是 sa_sigaction
            struct sigaction sigaction = previous_sa_sigactions[i];
            if (sigaction.sa_sigaction) {
                sigaction.sa_sigaction(signal, info, context);
            } else if (sigaction.sa_handler) {
                sigaction.sa_handler(signal);
            } else {
                // 源处理
                kill(getpid(), SIGKILL);
            }
            break;
        }
    }
}

static int cc_fatalSignals[] = {
    SIGHUP,
    SIGINT,
    SIGQUIT,
    SIGABRT,
    SIGILL,
    SIGSEGV,
    SIGFPE,
    SIGBUS,
    SIGPIPE
};

int cc_fatalSignalsCount(void){
    return (sizeof(cc_fatalSignals) / sizeof(cc_fatalSignals[0]));
}

const int* cc_fatalSignalsArray(void){
    return cc_fatalSignals;
}

static struct sigaction* previous_sa_sigactions = NULL; //新格的信号处理函数结构体数组

static void registerUncaughtSignalHandler(CCSig signal) {
    
    // 获取`cc_fatalSignals 原注入`，替换为己方任务
    const int* fatalSignals = cc_fatalSignalsArray();
    
    int fatalSignalsCount = cc_fatalSignalsCount();
    
    if(previous_sa_sigactions == NULL){
        previous_sa_sigactions = (struct sigaction *)malloc(sizeof(*previous_sa_sigactions) * (unsigned)fatalSignalsCount);
    }
    
    // 第1个参数：要操作的信号
    // 第2个参数：要设置的对信号的新处理方式
    // 第3个参数：原来对信号的处理方式
    // 返回值：0 表示成功，-1 表示有错误发生
    // int sigaction(int, const struct sigaction * __restrict, struct sigaction * __restrict);
    
    for (int i = 0; i < fatalSignalsCount; i++) {
        if (signal & fatalSignals[i]) {
            
            struct sigaction action;
            action.sa_handler = NULL;
            action.sa_sigaction = _UncaughtSignalHandler;
            
            // SA_RESTART：使被信号打断的系统调用自动重新发起
            // SA_NOCLDSTOP：使父进程在它的子进程暂停或继续运行时不会收到 SIGCHLD 信号
            // SA_NOCLDWAIT：使父进程在它的子进程退出时不会收到 SIGCHLD 信号，这时子进程如果退出也不会成为僵尸进程
            // SA_NODEFER：使对信号的屏蔽无效，即在信号处理函数执行期间仍能发出这个信号
            // SA_RESETHAND：信号处理之后重新设置为默认的处理方式
            // SA_SIGINFO：使用 sa_sigaction 成员而不是 sa_handler 作为信号处理函数
            action.sa_flags = (SA_NODEFER | SA_SIGINFO);
            sigemptyset(&action.sa_mask);
            
            if(sigaction(fatalSignals[i], &action, &previous_sa_sigactions[i]) != 0){
                sigaction(fatalSignals[i], &previous_sa_sigactions[i], NULL);
            }
        }
    }
}

@end
