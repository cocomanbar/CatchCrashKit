//
//  MamaNetworkBaseErrorResponse.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/23.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//  接口数据载体解析类：COMMON
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  错误类型的解析类
 */
@interface MamaNetworkBaseErrorResponse : NSObject

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy, nullable) NSString *msg;
@property (nonatomic, copy) NSError *error;

+ (instancetype)setDefaultModel:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
