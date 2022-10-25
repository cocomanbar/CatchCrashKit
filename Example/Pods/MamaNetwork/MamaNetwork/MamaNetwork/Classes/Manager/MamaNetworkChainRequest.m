//
//  MamaNetworkChainRequest.m
//  MamaNetwork
//
//  Created by tanxl on 2022/5/19.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkChainRequest.h"
#import <pthread/pthread.h>
#import "MamaNetworkChainRequestAgent.h"

@interface MamaNetworkChainRequest ()

@property (nonatomic, strong, readwrite) NSMutableArray *requestPrivateArray;
@property (nonatomic, strong, readwrite) NSMutableArray *resultBlocks;
@property (nonatomic, assign, readwrite) BOOL isExecuting;
@property (nonatomic, assign, readwrite) NSInteger indexing;
@property (nonatomic, assign) NSInteger nextRequestIndex;

@property (nonatomic, copy) MamaNetworkChainCallBackBlock defaultBlock;

@end

@implementation MamaNetworkChainRequest{
    pthread_mutex_t _lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _indexing = 0;
        _nextRequestIndex = 0;
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)addRequest:(MamaNetworkBaseRequest * _Nullable)aRequest callback:(nullable MamaNetworkChainCallBackBlock)callback {
    
    if (!aRequest || ![aRequest isKindOfClass:MamaNetworkBaseRequest.class]) {
        return;
    }
    if (self.isExecuting) {
        NSAssert(!self.isExecuting, @"列车已经屎向远方...");
        return;
    }
    pthread_mutex_lock(&self->_lock);
    [self.requestPrivateArray addObject:aRequest];
    [self.resultBlocks addObject:(callback ?: self.defaultBlock)];
    pthread_mutex_unlock(&self->_lock);
}

- (void)removeRequestArray {
    if (self.isExecuting) {
        NSAssert(!self.isExecuting, @"列车已经屎向远方...");
        return;
    }
    pthread_mutex_lock(&self->_lock);
    [self.requestPrivateArray removeAllObjects];
    [self.resultBlocks removeAllObjects];
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

- (NSArray *)requestArray {
    NSArray *requestArray;
    pthread_mutex_lock(&self->_lock);
    requestArray = [self.requestPrivateArray copy];
    pthread_mutex_unlock(&self->_lock);
    return requestArray;
}

- (NSInteger)indexing {
    return MAX(0, self.nextRequestIndex - 1);
}

- (void)start {
    if (!self.requestPrivateArray.count) {
        return;
    }
    if (self.isExecuting) {
        return;
    }
    self.isExecuting = true;
    [[MamaNetworkChainRequestAgent sharedAgent] addChainRequest:self];
    
    __weak typeof(self)weakSelf = self;
    for (int index = 0; index < self.requestPrivateArray.count; index++) {
        MamaNetworkBaseRequest *request = [self.requestPrivateArray objectAtIndex: index];
        NSAssert(!request.isExecuting, @"请把请求的控制交给 Chain 管理!");
        NSAssert(!(request.cacheMode == MamaNetworkCacheModeDone), @"将不支持 读取缓存策略这一项，会干扰到结果回调！");
        // 1.1.将置空其本身的插件，由 Chain 添加和管理.
        [request.components removeAllObjects];
        // 1.2.将置空其本身的回调，把回调自动交给 Batch.
        request.successBlock = ^(id  _Nullable response) {
            [weakSelf requestFinished:response error:nil type:1];
        };
        request.failureBlock = ^(id  _Nullable response) {
            [weakSelf requestFinished:response error:nil type:2];
        };
        request.netErrorBlock = ^(MamaNetworkBaseErrorResponse * _Nullable error) {
            [weakSelf requestFinished:nil error:error type:3];
        };
    }
    
    /// 🎃🎃🎃插件协议
    [self makeComponentPerformImp:(MamaNetworkImpChainStart)];
    
    [self startNextRequest];
}

- (BOOL)startNextRequest {
    
    pthread_mutex_lock(&self->_lock);
    if (self.nextRequestIndex < self.requestPrivateArray.count) {
        MamaNetworkBaseRequest *aRequest = [self.requestPrivateArray objectAtIndex:self.nextRequestIndex];
        self.nextRequestIndex ++;
        [aRequest start];
        pthread_mutex_unlock(&self->_lock);
        return true;
    } else {
        pthread_mutex_unlock(&self->_lock);
        return false;
    }
}

- (void)stop {
    
    [self stopFlag:false];
}

- (void)stopFlag:(BOOL)flag {
    
    if (flag) {
        pthread_mutex_lock(&self->_lock);
        MamaNetworkBaseRequest *currentReq = [self.requestPrivateArray objectAtIndex:self.indexing];
        [currentReq cancel];
        pthread_mutex_unlock(&self->_lock);
        
        if (self.completionBlock) {
            self.completionBlock(self, true);
        }
    }
    
    /// 🎃🎃🎃插件协议
    [self makeComponentPerformImp:(MamaNetworkImpChainCancelled)];
    
    [self.requestPrivateArray removeAllObjects];
    [self.resultBlocks removeAllObjects];
    self.completionBlock = nil;
    self.isExecuting = false;
    [[MamaNetworkChainRequestAgent sharedAgent] removeChainRequest:self];
}

/**
 *  统一处理数据
 *      type = 1：成功的回调
 *      type = 2：失败的回调
 *      type = 3：错误的回调
 */
- (void)requestFinished:(id)response error:(MamaNetworkBaseErrorResponse *)error type:(int)type{

    // 当前的请求回调
    pthread_mutex_lock(&self->_lock);
    MamaNetworkBaseRequest *currentReq = [self.requestArray objectAtIndex:self.indexing];
    MamaNetworkChainCallBackBlock callback = [self.resultBlocks objectAtIndex:self.indexing];
    pthread_mutex_unlock(&self->_lock);
    
    if (callback && !callback(self, currentReq, response, error)) {
        [self stopFlag:true];
        return;
    }
    
    if (![self startNextRequest]) {
        if (self.completionBlock) {
            self.completionBlock(self, false);
        }
        /// 🎃🎃🎃插件协议
        [self makeComponentPerformImp:(MamaNetworkImpChainFinished)];
        self.isExecuting = false;
        [[MamaNetworkChainRequestAgent sharedAgent] removeChainRequest:self];
    }
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
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

#pragma mark - Getter

- (MamaNetworkChainCallBackBlock)defaultBlock {
    if (!_defaultBlock) {
        _defaultBlock = ^BOOL(MamaNetworkChainRequest * _Nonnull chainRequest,
                                MamaNetworkBaseRequest * _Nonnull aRequest,
                                id  _Nonnull response,
                                MamaNetworkBaseErrorResponse * _Nonnull error)
        {
            // do nothine..
            return true;
        };
    }
    return _defaultBlock;
}

- (NSMutableArray *)resultBlocks {
    if (!_resultBlocks) {
        _resultBlocks = [NSMutableArray array];
    }
    return _resultBlocks;
}

- (NSMutableArray *)requestPrivateArray {
    if (!_requestPrivateArray) {
        _requestPrivateArray = [NSMutableArray array];
    }
    return _requestPrivateArray;
}

@end
