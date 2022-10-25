//
//  MamaNetworkBatchRequest.m
//  MamaNetwork
//
//  Created by tanxl on 2022/5/19.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkBatchRequest.h"
#import <pthread/pthread.h>
#import "MamaNetworkBatchRequestAgent.h"

@interface MamaNetworkBatchRequest ()

@property (nonatomic, assign, readwrite) BOOL isExecuting;

@property (nonatomic, assign) NSInteger finishedCount;

@property (nonatomic, strong, readwrite) NSMutableArray *requestPrivateArray;
@property (nonatomic, strong, readwrite) NSMutableArray *resutlsPrivate;

@end

@implementation MamaNetworkBatchRequest{
    pthread_mutex_t _lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (instancetype)initWithRequestArray:(NSArray<MamaNetworkBaseRequest *> *)requestArray {
    self = [self init];
    if (self) {
        
        if (requestArray && [requestArray isKindOfClass:NSArray.class]) {
            [self.requestPrivateArray addObjectsFromArray:requestArray];
        }
    }
    return self;
}

- (void)addRequest:(MamaNetworkBaseRequest *)aRequest {
    if (!aRequest || ![aRequest isKindOfClass:MamaNetworkBaseRequest.class]) {
        return;
    }
    if (self.isExecuting) {
        NSAssert(!self.isExecuting, @"列车已经屎向远方...");
        return;
    }
    pthread_mutex_lock(&self->_lock);
    [self.requestPrivateArray addObject:aRequest];
    pthread_mutex_unlock(&self->_lock);
}

- (void)addComponent:(id<MamaNetworkComponentProtocol> _Nullable)component {
    if (!component) {
        return;
    }
    if (!self.components) {
        self.components = [NSMutableArray array];
    }
    [self.components addObject:component];
}

- (void)clearCompletionBlock {
    if (_batchCompletionBlock) {
        _batchCompletionBlock = nil;
    }
}

- (void)removeRequestArray {
    if (self.isExecuting) {
        NSAssert(!self.isExecuting, @"列车已经屎向远方...");
        return;
    }
    pthread_mutex_lock(&self->_lock);
    [self.requestPrivateArray removeAllObjects];
    pthread_mutex_unlock(&self->_lock);
}

- (void)start {
    if (!self.requestArray.count) {
        return;
    }
    if (self.isExecuting) {
        return;
    }
    self.isExecuting = true;
    [[MamaNetworkBatchRequestAgent sharedAgent] addBatchRequest:self];
    
    // 1.严格按照请求添加顺序返回对应的请求结果
    __weak typeof(self)weakSelf = self;
    for (int index = 0; index < self.requestArray.count; index++) {
        MamaNetworkBaseRequest *request = [self.requestArray objectAtIndex: index];
        NSAssert(!request.isExecuting, @"请把请求的控制交给 Batch 管理!");
        NSAssert(!(request.cacheMode == MamaNetworkCacheModeDone), @"将不支持 读取缓存策略这一项，会干扰到结果回调！");
        // 1.1.将置空其本身的插件，由 Batch 添加和管理.
        [request.components removeAllObjects];
        // 1.2.将置空其本身的回调，把回调自动交给 Batch.
        request.successBlock = ^(id  _Nullable response) {
            [weakSelf requestFinished:response atIndex:index type:1];
        };
        request.failureBlock = ^(id  _Nullable response) {
            [weakSelf requestFinished:response atIndex:index type:2];
        };
        request.netErrorBlock = ^(MamaNetworkBaseErrorResponse * _Nullable error) {
            [weakSelf requestFinished:error atIndex:index type:3];
        };
        // 1.4.占位数据
        [self.resutlsPrivate addObject: [NSNull null]];
    }
    
    /// 🎃🎃🎃插件协议
    [self makeComponentPerformImp:(MamaNetworkImpBatchStart)];
    
    // 2.统一发起请求
    for (int index = 0; index < self.requestArray.count; index++) {
        MamaNetworkBaseRequest *request = [self.requestArray objectAtIndex: index];
        [request start];
    }
}

- (void)stop {
    for (MamaNetworkBaseRequest *request in self.requestArray) {
        [request cancel];
    }
    self.isExecuting = false;
    [self clearCompletionBlock];
    [self makeComponentPerformImp:(MamaNetworkImpBatchCancelled)];
    [[MamaNetworkBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

/**
 *  统一处理数据
 *      type = 1：成功的回调
 *      type = 2：失败的回调
 *      type = 3：错误的回调
 */
- (void)requestFinished:(id)row atIndex:(int)index type:(int)type{

    NSAssert((row != nil), @"请求回调数据异常!");
    pthread_mutex_lock(&self->_lock);
    // 记录请求完成数
    self.finishedCount += 1;
    // 插入网络数据
    if (self.dataMode == MamaNetworkBatchDataModePure && type == 1) {
        [self.resutlsPrivate replaceObjectAtIndex:index withObject:row?:[NSNull null]];
    }
    if (self.dataMode == MamaNetworkBatchDataModeWrap) {
        MamaNetworkRequestPackage *aPackage = [[MamaNetworkRequestPackage alloc] init];
        aPackage.index = index;
        if (type == 1) {
            aPackage.succeedResponse = row;
        } else if (type == 2) {
            aPackage.failedResponse = row;
        } else {
            aPackage.error = row;
        }
        [self.resutlsPrivate replaceObjectAtIndex:index withObject:aPackage];
    }
    pthread_mutex_unlock(&self->_lock);
    
    // 请求完毕
    if (self.finishedCount == self.requestArray.count) {
        
        /// 🎃🎃🎃插件协议
        [self makeComponentPerformImp:(MamaNetworkImpBatchFinished)];
        
        if (self.batchCompletionBlock) {
            self.batchCompletionBlock([self.resutls copy]);
        }
        self.isExecuting = false;
        [self clearCompletionBlock];
        [[MamaNetworkBatchRequestAgent sharedAgent] removeBatchRequest:self];
    }
}

#pragma mark - private

- (void)makeComponentPerformImp:(MamaNetworkImp)imp {
    if (!self.components || !self.components.count) {
        return;
    }
    
    void(^componentPerformImp)(id<MamaNetworkComponentProtocol>component, SEL aSel) =
    ^(id<MamaNetworkComponentProtocol>component, SEL aSel) {
        if ([component respondsToSelector:aSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [component performSelector:aSel withObject:self];
#pragma clang diagnostic pop
        }
    };
    for (id<MamaNetworkComponentProtocol>component in self.components) {
        if (imp & MamaNetworkImpBatchStart) {
            SEL aSel = @selector(requestBatchWillStart:);
            componentPerformImp(component, aSel);
        }
        if (imp & MamaNetworkImpBatchFinished) {
            SEL aSel = @selector(requestBatchDidFinished:);
            componentPerformImp(component, aSel);
        }
        if (imp & MamaNetworkImpBatchCancelled) {
            SEL aSel = @selector(requestBatchDidCancelled:);
            componentPerformImp(component, aSel);
        }
    }
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

#pragma mark - Getter

- (NSMutableArray *)resutlsPrivate {
    if (!_resutlsPrivate) {
        _resutlsPrivate = [NSMutableArray array];
    }
    return _resutlsPrivate;
}

- (NSMutableArray *)requestPrivateArray {
    if (!_requestPrivateArray) {
        _requestPrivateArray = [NSMutableArray array];
    }
    return _requestPrivateArray;
}

@end
