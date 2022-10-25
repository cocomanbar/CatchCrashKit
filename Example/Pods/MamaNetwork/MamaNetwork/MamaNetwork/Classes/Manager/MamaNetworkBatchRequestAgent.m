//
//  MamaNetworkBatchRequestAgent.m
//  MamaNetwork
//
//  Created by tanxl on 2022/5/21.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkBatchRequestAgent.h"
#import "MamaNetworkBatchRequest.h"
#import <pthread/pthread.h>

@interface MamaNetworkBatchRequestAgent ()

@property (strong, nonatomic) NSMutableArray<MamaNetworkBatchRequest *> *requestArray;

@end

@implementation MamaNetworkBatchRequestAgent{
    pthread_mutex_t _lock;
}

+ (instancetype)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

- (void)addBatchRequest:(MamaNetworkBatchRequest * _Nullable)request {
    if (![request isKindOfClass:MamaNetworkBatchRequest.class]) {
        return;
    }
    pthread_mutex_lock(&self->_lock);
    if (![self.requestArray containsObject:request]) {
        [self.requestArray addObject:request];
    }
    pthread_mutex_unlock(&self->_lock);
}

- (void)removeBatchRequest:(MamaNetworkBatchRequest * _Nullable)request {
    if (![request isKindOfClass:MamaNetworkBatchRequest.class]) {
        return;
    }
    pthread_mutex_lock(&self->_lock);
    if ([self.requestArray containsObject:request]) {
        [self.requestArray removeObject:request];
    }
    pthread_mutex_unlock(&self->_lock);
}

- (NSMutableArray *)requestArray{
    if (!_requestArray) {
        _requestArray = [NSMutableArray array];
    }
    return _requestArray;
}

@end
