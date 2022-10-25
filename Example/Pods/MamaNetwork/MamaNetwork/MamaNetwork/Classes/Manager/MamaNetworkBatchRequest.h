//
//  MamaNetworkBatchRequest.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/19.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MamaNetworkBaseRequest.h"
#import "MamaNetworkRequestPackage.h"
#import "MamaNetworkComponentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MamaNetworkBatchCompletionBlock) (NSArray <id>* _Nullable batchDatas);

/**
 *  Batch 队列😈
 *
 *  使用注意：💥任何加进来的Request请求💥
 *      1.将置空其本身的回调，把回调自动交给 Batch.
 *      2.将置空其本身的插件，由 Batch 添加和管理.
 *      
 */
@interface MamaNetworkBatchRequest : NSObject

// 请求列表
@property (nonatomic, strong, readonly) NSArray *requestArray;

// 请求结果
@property (nonatomic, strong, readonly) NSArray *resutls;

// 严格按照请求添加顺序返回对应的请求结果
@property (nonatomic, copy, nullable) MamaNetworkBatchCompletionBlock batchCompletionBlock;

// 插件列表
@property (nonatomic, strong, nullable) NSMutableArray <id<MamaNetworkComponentProtocol>>*components;

// 是否在执行中
@property (nonatomic, assign, readonly) BOOL isExecuting;

// 数据回调策略
@property (nonatomic, assign) MamaNetworkBatchDataMode dataMode;

- (instancetype)initWithRequestArray:(NSArray<MamaNetworkBaseRequest *> * _Nullable)requestArray;

- (void)addRequest:(MamaNetworkBaseRequest * _Nullable)aRequest;

- (void)addComponent:(id<MamaNetworkComponentProtocol> _Nullable)component;

- (void)clearCompletionBlock;

- (void)removeRequestArray;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
