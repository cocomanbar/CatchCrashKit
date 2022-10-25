//
//  MamaNetworkComponentProtocol.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/20.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  插件协议
 */
@class MamaNetworkBaseRequest;
@class MamaNetworkBatchRequest;

typedef NS_OPTIONS(NSUInteger, MamaNetworkImp){
    MamaNetworkImpNone              = 0,
    MamaNetworkImpWillStart         = 1 << 0,
    MamaNetworkImpReceiveCacheData  = 1 << 1,
    MamaNetworkImpReceiveNetData    = 1 << 2,
    MamaNetworkImpDealNetError      = 1 << 3,
    MamaNetworkImpDealNetSucceed    = 1 << 4,
    MamaNetworkImpCancelled         = 1 << 5,
    MamaNetworkImpBatchStart        = 1 << 6,
    MamaNetworkImpBatchCancelled    = 1 << 7,
    MamaNetworkImpBatchFinished     = 1 << 8,
    MamaNetworkImpChainStart        = 1 << 9,
    MamaNetworkImpChainCancelled    = 1 << 10,
    MamaNetworkImpChainFinished     = 1 << 11,
};

@protocol MamaNetworkComponentProtocol <NSObject>

/**
 *  注意：
 *  以下方法里想确切知道网络的可靠数据，请从 responseObject or error 属性获取。
 */
@optional

/// 即将发起请求
- (void)requestWillStart:(MamaNetworkBaseRequest * _Nullable)request;

/// 从本地拿到一个缓存数据
- (void)requestReceiveCacheData:(MamaNetworkBaseRequest * _Nullable)request;

/// 从网络拿到一个数据
- (void)requestReceiveNetData:(MamaNetworkBaseRequest * _Nullable)request;

/// 网络数据处理失败
- (void)requestDealNetError:(MamaNetworkBaseRequest * _Nullable)request;

/// 网络数据处理成功
- (void)requestDealNetSucceed:(MamaNetworkBaseRequest * _Nullable)request;

/// 请求取消
- (void)requestDidCancelled:(MamaNetworkBaseRequest * _Nullable)request;

/// Batch请求
- (void)requestBatchWillStart:(MamaNetworkBatchRequest * _Nullable)request;
- (void)requestBatchDidCancelled:(MamaNetworkBatchRequest * _Nullable)request;
- (void)requestBatchDidFinished:(MamaNetworkBatchRequest * _Nullable)request;

/// Chain请求
- (void)requestChainWillStart:(MamaNetworkBatchRequest * _Nullable)request;
- (void)requestChainDidCancelled:(MamaNetworkBatchRequest * _Nullable)request;
- (void)requestChainDidFinished:(MamaNetworkBatchRequest * _Nullable)request;

@end

NS_ASSUME_NONNULL_END
