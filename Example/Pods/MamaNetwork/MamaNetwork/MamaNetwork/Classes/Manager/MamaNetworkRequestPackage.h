//
//  MamaNetworkRequestPackage.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/21.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MamaNetworkBaseErrorResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MamaNetworkBatchDataMode){
    MamaNetworkBatchDataModePure = 0,   // 只关注成功信息：请求回调只包含  succeed or null
    MamaNetworkBatchDataModeWrap,       // RowWrap
};

@interface MamaNetworkRequestPackage : NSObject

// 在队列的位置
@property (nonatomic, assign) int index;

// 区分 sign or token
@property (nonatomic, strong, nullable) id succeedResponse;
@property (nonatomic, strong, nullable) id failedResponse;
@property (nonatomic, strong, nullable) MamaNetworkBaseErrorResponse *error;

@end

NS_ASSUME_NONNULL_END
