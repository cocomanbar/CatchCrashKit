//
//  MamaNetworkChainRequest.h
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

@class MamaNetworkChainRequest;

typedef BOOL(^MamaNetworkChainCallBackBlock) (MamaNetworkChainRequest * _Nullable chainRequest,
                                              MamaNetworkBaseRequest * _Nullable aRequest,
                                              id _Nullable response,
                                              MamaNetworkBaseErrorResponse *  _Nullable error);

typedef void(^MamaNetworkChainCompletionBlock)(MamaNetworkChainRequest * _Nullable chainRequest, BOOL isInterrupt);

/**
 *  Chain 队列😈
 *
 *  使用注意：💥任何加进来的Request请求💥
 *      1.将置空其本身的回调，把回调自动交给 Chain.
 *      2.将置空其本身的插件，由 Chain 添加和管理.
 *
 */
@interface MamaNetworkChainRequest : NSObject

// 请求列表
@property (nonatomic, strong, readonly) NSArray *requestArray;

// 插件列表
@property (nonatomic, strong, nullable) NSMutableArray <id<MamaNetworkComponentProtocol>>*components;

// 是否在执行中
@property (nonatomic, assign, readonly) BOOL isExecuting;

// 当前正在发生请求的index
@property (nonatomic, assign, readonly) NSInteger indexing;

// 队列完成的回调
@property (nonatomic, copy, nullable) MamaNetworkChainCompletionBlock completionBlock;



- (void)addRequest:(MamaNetworkBaseRequest * _Nullable)aRequest callback:(MamaNetworkChainCallBackBlock _Nullable)callback;

- (void)addComponent:(id<MamaNetworkComponentProtocol> _Nullable)component;

- (void)start;

- (void)stop;

- (void)removeRequestArray;

@end

NS_ASSUME_NONNULL_END
