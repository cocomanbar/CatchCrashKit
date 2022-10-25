//
//  MamaNetworkDataResponse.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/19.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  SIGN 验签方式的解析类
 *
 *  当我们需要一个字典类型的data时，推荐使用。
 */
@interface MamaNetworkDataResponse : MamaNetworkBaseResponse

/** 数据字典*/
@property (nonatomic, strong, nullable) NSDictionary *data;

@end

NS_ASSUME_NONNULL_END
