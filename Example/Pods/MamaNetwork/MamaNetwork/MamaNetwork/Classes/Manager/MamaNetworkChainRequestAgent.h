//
//  MamaNetworkChainRequestAgent.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/21.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MamaNetworkChainRequest;

@interface MamaNetworkChainRequestAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedAgent;

- (void)addChainRequest:(MamaNetworkChainRequest * _Nullable)request;

- (void)removeChainRequest:(MamaNetworkChainRequest * _Nullable)request;

@end

NS_ASSUME_NONNULL_END
