//
//  MamaNetworkBaseRequest.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkBaseRequest.h"
#import "MamaNetworkRequestAgent.h"
#import <pthread/pthread.h>
#import "NSString+MamaNetwork.h"
#import "NSMutableDictionary+MamaNetwork.h"

@interface MamaNetworkBaseRequest ()

/// 记录网络任务标识容器，记录当前对象的当前生命周期内的网络请求情况
@property (nonatomic, strong) NSMutableArray<NSURLSessionTask *> *dataTasks;

/// 缓存器
@property (nonatomic, strong) MamaNetworkCache *cacheHandler;

/// 缓存数据备份
@property (nonatomic ,strong) NSMutableDictionary *cacheDict;

@end

@implementation MamaNetworkBaseRequest{
    pthread_mutex_t _lock;
}

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _releaseStrategy = MamaNetworkReleaseStrategyWhenRequestDealloc;
        _repeatStrategy = MamaNetworkRepeatStrategyAllAllowed;
        _cacheBackStrategy = MamaNetworkCacheBackModeRequestStart;
        _cacheMode = MamaNetworkCacheModeNone;
        _requestCode = 0;
        _timeInterval = 15;
        _enableDomain = true;
    }
    return self;
}

- (void)dealloc {
    if (self.releaseStrategy == MamaNetworkReleaseStrategyWhenRequestDealloc) {
        [self cancelFlag:(true)];
    }
    pthread_mutex_destroy(&_lock);
}

#pragma mark - public

- (void)cancel {
    [self cancelFlag:(false)];
}

- (void)cancelFlag:(BOOL)dealloc {
    [self clearRequestBlocks];
    pthread_mutex_lock(&self->_lock);
    [[MamaNetworkRequestAgent shared] cancelTaskWithSessionTasks:[self.dataTasks copy]];
    [self.dataTasks removeAllObjects];
    pthread_mutex_unlock(&self->_lock);
    /// 🎃🎃🎃插件协议
    if (!dealloc) {
        [self makeComponentPerformImp:(MamaNetworkImpCancelled)];
    }
}

- (BOOL)isExecuting {
    pthread_mutex_lock(&self->_lock);
    BOOL isExecuting = self.dataTasks.count > 0;
    pthread_mutex_unlock(&self->_lock);
    return isExecuting;
}

- (void)addComponent:(id<MamaNetworkComponentProtocol>)component {
    if (!self.components) {
        self.components = [NSMutableArray array];
    }
    if (component) {
        [self.components addObject:component];
    }
}

- (void)startWithSuccess:( MamaRequestSuccessBlock)successBlock
                 failure:( MamaRequestFailureBlock)failureBlock
                netError:( MamaRequestNetErrorBlock)netErrorBlock{
    [self startWithCache:nil success:successBlock failure:failureBlock netError:netErrorBlock];
}

- (void)startWithCache:( MamaRequestCacheBlock)cacheBlock
               success:( MamaRequestSuccessBlock)successBlock
               failure:( MamaRequestFailureBlock)failureBlock
              netError:( MamaRequestNetErrorBlock)netErrorBlock{
    self.cacheBlock = cacheBlock;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.netErrorBlock = netErrorBlock;
    [self start];
}

- (void)start {
    
    if (self.isExecuting) {
        switch (self.repeatStrategy) {
            case MamaNetworkRepeatStrategyCancelNewest: return;
            case MamaNetworkRepeatStrategyCancelOldest: {
                [self cancel];
            }
                break;
            default: break;
        }
    }
    
    /// 🎃🎃🎃插件协议
    [self makeComponentPerformImp:(MamaNetworkImpWillStart)];
    
    if (self.cacheMode == MamaNetworkCacheModeNone) {
        [self startWithCacheKey:nil];
        return;
    }
    
    NSString *cacheKey = [self requestCacheKey];
    [self.cacheHandler objectForKey:cacheKey withBlock:^(NSString * key, id<NSCoding> object) {
        
        ///未缓存命中
        if (!object) {
            [self startWithCacheKey:cacheKey];
            return;
        }
        ///缓存命中
        MamaNetworkBaseResponse *response;
        if (self.modelClass) {
            NSString *classesName = NSStringFromClass(self.modelClass);
            response = [NSClassFromString(classesName) mj_objectWithKeyValues:object];
        }else{
            response = [MamaNetworkBaseResponse mj_objectWithKeyValues:object];
        }
        ///缓存命中后也发起请求
        if (self.cacheHandler.readMode == MamaNetworkCacheReadModeAlsoNetwork) {
            ///cache回调策略
            if (self.cacheBackStrategy == MamaNetworkCacheBackModeRequestStart) {
                [self requestSuccessWithResponse:response cacheKey:cacheKey fromCache:YES];
            }else{
                [self.cacheDict network_setObject:response forKey:key];
            }
            [self startWithCacheKey:cacheKey];
        }
        ///缓存命中后不发起请求
        else if (self.cacheHandler.readMode == MamaNetworkCacheReadModeCancelNetwork){
            ///cache回调策略
            [self requestSuccessWithResponse:response cacheKey:cacheKey fromCache:YES];
        }
    }];
}

#pragma mark - request

- (void)startWithCacheKey:(NSString *)cacheKey {
    __block NSURLSessionTask *dataTask = nil;
    if (self.releaseStrategy == MamaNetworkReleaseStrategyHoldRequest) {
        dataTask = [[MamaNetworkRequestAgent shared] startNetworkingWithRequest:self completion:^(id responseObject, NSError *error) {
            self.error = error;
            self.responseJsonObject = responseObject;
            
            if (error) {
                [self requestErrorFailureWithResponse:error];
            }else{
                [self requestCompletionWithResponse:responseObject cacheKey:cacheKey fromCache:NO];
            }
            
            pthread_mutex_lock(&self->_lock);
            [self.dataTasks removeObject:dataTask];
            pthread_mutex_unlock(&self->_lock);
        }];
        
    } else {
        __weak typeof(self) weakSelf = self;
        dataTask = [[MamaNetworkRequestAgent shared] startNetworkingWithRequest:weakSelf completion:^(id responseObject, NSError *error) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.error = error;
            self.responseJsonObject = responseObject;
            
            if (error) {
                [self requestErrorFailureWithResponse:error];
            }else{
                [self requestCompletionWithResponse:responseObject cacheKey:cacheKey fromCache:NO];
            }
            
            pthread_mutex_lock(&self->_lock);
            [self.dataTasks removeObject:dataTask];
            pthread_mutex_unlock(&self->_lock);
        }];
    }
    
    if (dataTask) {
        self.dataTask = dataTask;
        pthread_mutex_lock(&self->_lock);
        [self.dataTasks addObject:dataTask];
        pthread_mutex_unlock(&self->_lock);
    }
}

#pragma mark - response

- (void)requestErrorFailureWithResponse:(NSError *)error{
    
    /// 🎃🎃🎃插件协议
    [self makeComponentPerformImp:(MamaNetworkImpReceiveNetData | MamaNetworkImpDealNetError)];
    
    MamaNetworkBaseErrorResponse *errorModel = [MamaNetworkBaseErrorResponse setDefaultModel:error];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.netErrorBlock) {
            self.netErrorBlock(errorModel);
        }
        if (self.cacheBackStrategy == MamaNetworkCacheBackModeRequestEnd) {
            NSString *cacheKey = [self requestCacheKey];
            MamaNetworkBaseResponse *response = [self.cacheDict objectForKey:cacheKey];
            if (response) {
                if (self.cacheBlock) {
                    self.cacheBlock(response);
                }
            }
        }
        [self clearRequestBlocks];
    });
}

- (void)requestCompletionWithResponse:(id)responseObject cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache {
    
    /// 业务解析
    Class classesName = self.modelClass;
    if ([self isTokenApi]) {
        classesName = classesName?:[MamaNetworkBaseTokenResponse class];
        MamaNetworkBaseTokenResponse *response = [classesName mj_objectWithKeyValues:responseObject];
        if ([response isKindOfClass:MamaNetworkBaseTokenResponse.class]) {
            response.responseJSONObject = responseObject;
            if (response.status != self.requestCode) {
                [self requestFailureWithResponse:response];
            }else{
                [self requestSuccessWithResponse:response cacheKey:cacheKey fromCache:NO];
            }
        } else {
            if ([response respondsToSelector:@selector(setResponseJSONObject:)]) {
                [response setResponseJSONObject:responseObject];
            }
            if ([response respondsToSelector:@selector(status)]) {
                if (response.status != self.requestCode) {
                    [self requestFailureWithResponse:response];
                }else{
                    [self requestSuccessWithResponse:response cacheKey:cacheKey fromCache:NO];
                }
            }else{
                [self requestFailureWithResponse:response];
            }
        }
        
    }else{
        classesName = classesName ?: [MamaNetworkBaseResponse class];
        MamaNetworkBaseResponse *response = [classesName mj_objectWithKeyValues:responseObject];
        if ([response isKindOfClass:MamaNetworkBaseResponse.class]) {
            response.responseJSONObject = responseObject;
            if (response.code != self.requestCode) {
                [self requestFailureWithResponse:response];
            } else {
                [self requestSuccessWithResponse:response cacheKey:cacheKey fromCache:NO];
            }
        } else {
            if ([response respondsToSelector:@selector(setResponseJSONObject:)]) {
                [response setResponseJSONObject:responseObject];
            }
            if ([response respondsToSelector:@selector(code)]) {
                if (response.code != self.requestCode) {
                    [self requestFailureWithResponse:response];
                }else{
                    [self requestSuccessWithResponse:response cacheKey:cacheKey fromCache:NO];
                }
            }else{
                [self requestFailureWithResponse:response];
            }
        }
    }
}

- (void)requestFailureWithResponse:(id)response {

    /// 🎃🎃🎃插件协议
    [self makeComponentPerformImp:(MamaNetworkImpReceiveNetData | MamaNetworkImpDealNetError)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.failureBlock) {
            self.failureBlock(response);
        }
        
        /// 回调缓存
        if (self.cacheBackStrategy == MamaNetworkCacheBackModeRequestEnd) {
            NSString *cacheKey = [self requestCacheKey];
            MamaNetworkBaseResponse *response = [self.cacheDict objectForKey:cacheKey];
            if (response) {
                if (self.cacheBlock) {
                    self.cacheBlock(response);
                }
            }
        }
        [self clearRequestBlocks];
    });
}

- (void)requestSuccessWithResponse:(id)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache {
    
    /// 回调数据
    if (fromCache) {
                
        /// 🎃🎃🎃插件协议
        [self makeComponentPerformImp:(MamaNetworkImpReceiveCacheData)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.cacheBlock) {
                self.cacheBlock(response);
            }
        });
    } else {

        /// 🎃🎃🎃插件协议
        [self makeComponentPerformImp:(MamaNetworkImpReceiveNetData | MamaNetworkImpDealNetSucceed)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.successBlock) {
                self.successBlock(response);
            }
            [self clearRequestBlocks];
        });
    }
    
    /// 缓存【下载/上传不参与缓存】
    if (self.cacheMode == MamaNetworkCacheModeDone) {
        BOOL shouldCache = false;
        NSDictionary *json = [response mj_keyValues];
        if (self.cacheHandler.shouldCacheBlock) {
            shouldCache = self.cacheHandler.shouldCacheBlock(json);
        }
        if (self.data.length) {
            shouldCache = false;
        }
        if (!fromCache && shouldCache) {
            [self.cacheHandler setObject:json forKey:cacheKey];
        }
    }
}

#pragma mark - private

- (void)makeComponentPerformImp:(MamaNetworkImp)imp {
    if (!self.components || !self.components.count) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        void(^componentPerformImp)(id<MamaNetworkComponentProtocol>component, SEL aSel) = ^(id<MamaNetworkComponentProtocol>component, SEL aSel) {
            if ([component respondsToSelector:aSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [component performSelector:aSel withObject:self];
#pragma clang diagnostic pop
            }
        };
        for (id<MamaNetworkComponentProtocol>component in self.components) {
            if (imp & MamaNetworkImpWillStart) {
                SEL aSel = @selector(requestWillStart:);
                componentPerformImp(component, aSel);
            }
            if (imp & MamaNetworkImpReceiveCacheData) {
                SEL aSel = @selector(requestReceiveCacheData:);
                componentPerformImp(component, aSel);
            }
            if (imp & MamaNetworkImpReceiveNetData) {
                SEL aSel = @selector(requestReceiveNetData:);
                componentPerformImp(component, aSel);
            }
            if (imp & MamaNetworkImpDealNetError) {
                SEL aSel = @selector(requestDealNetError:);
                componentPerformImp(component, aSel);
            }
            if (imp & MamaNetworkImpDealNetSucceed) {
                SEL aSel = @selector(requestDealNetSucceed:);
                componentPerformImp(component, aSel);
            }
            if (imp & MamaNetworkImpCancelled) {
                SEL aSel = @selector(requestDidCancelled:);
                componentPerformImp(component, aSel);
            }
        }
        
    });
}

- (void)clearRequestBlocks {
    self.cacheBlock = nil;
    self.successBlock = nil;
    self.failureBlock = nil;
    self.netErrorBlock = nil;
}

/// 缓存内容对应的KEY：需要剔除t参数，对应的32位MD5
- (NSString *)requestCacheKey {
    NSString *requestMethodString = [self requestMethodString];
    NSString *requestURLString = [self requestURLString];
    NSString *requestParameter = [self stringFromParameter:self.requestParameter];
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@%@", requestMethodString, requestURLString, requestParameter];
    if (self.cacheHandler.customCacheKeyBlock) {
        cacheKey = self.cacheHandler.customCacheKeyBlock(cacheKey);
    }
    cacheKey = [cacheKey mamaNetwork_md5];
    return cacheKey;
}

- (NSString *)stringFromParameter:(NSDictionary *)apiDict {
    NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithDictionary:apiDict?:@{}];
    [parameter addEntriesFromDictionary:[self parameterForRequest:self]];
    
    NSMutableString *string = [NSMutableString string];
    NSArray *allKeys = [parameter.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[NSString stringWithFormat:@"%@", obj1] compare:[NSString stringWithFormat:@"%@", obj2] options:NSLiteralSearch];
    }];
    for (id key in allKeys) {
        if (self.cacheIgnoreKeysArray.count) {
            if ([self.cacheIgnoreKeysArray containsObject:key]) {
                continue;
            }
        }
        [string appendString:[NSString stringWithFormat:@"%@%@=%@", string.length > 0 ? @"&" : @"?", key, [parameter objectForKey:key]]];
    }
    return string;
}

- (NSDictionary *)parameterForRequest:(MamaNetworkBaseRequest *)request {
    NSDictionary *parameter = request.requestParameter;
    if ([request respondsToSelector:@selector(mamanetwork_preprocessParameter:)]) {
        parameter = [request mamanetwork_preprocessParameter:parameter];
    }
    return parameter;
}

- (NSString *)requestURLString {
    if (self.mockURI.length) {
        return self.mockURI;
    }
    NSURL *baseURL = [NSURL URLWithString:self.baseURI];
    NSString *URLString = [NSURL URLWithString:self.requestURI relativeToURL:baseURL].absoluteString;
    return URLString;
}

- (NSString *)requestMethodString {
    switch (self.requestMethod) {
        case MamaRequestMethodGET: return @"GET";
        case MamaRequestMethodPOST: return @"POST";
        case MamaRequestMethodUPLOAD: return @"UPLOAD";
        case MamaRequestMethodPOST_TOKEN: return @"POST_TOKEN";
        case MamaRequestMethodGET_TOKEN: return @"GET_TOKEN";
        case MamaRequestMethodUPLOAD_TOKEN: return @"UPLOAD_TOKEN";
        case MamaRequestMethodSearch: return @"GET";
    }
}

- (BOOL)isTokenApi{
    switch (self.requestMethod) {
        case MamaRequestMethodGET: return NO;
        case MamaRequestMethodPOST: return NO;
        case MamaRequestMethodUPLOAD: return NO;
        case MamaRequestMethodPOST_TOKEN: return YES;
        case MamaRequestMethodGET_TOKEN: return YES;
        case MamaRequestMethodUPLOAD_TOKEN: return YES;
        case MamaRequestMethodSearch: return NO;
    }
}

#pragma mark - getter

- (NSMutableArray<NSURLSessionTask *> *)dataTasks {
    if (!_dataTasks) {
        _dataTasks = [NSMutableArray array];
    }
    return _dataTasks;
}

- (MamaNetworkCache *)cacheHandler {
    if (!_cacheHandler) {
        _cacheHandler = [[MamaNetworkCache alloc] init];
        _cacheHandler.readMode = MamaNetworkCacheReadModeNone;
        _cacheHandler.writeMode = MamaNetworkCacheWriteModeNone;
    }
    return _cacheHandler;
}

- (NSMutableDictionary *)cacheDict{
    if (!_cacheDict) {
        _cacheDict = [NSMutableDictionary dictionary];
    }
    return _cacheDict;
}

@end
