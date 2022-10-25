//
//  MamaNetworkBaseResponse.h
//  MamaNetwork
//
//  Created by cocomanber on 2019/4/16.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//  接口数据载体解析类：SIGN
//  初始化接口请求类时，直接传继承于此类的子类方便做初始化数据
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  SIGN 验签方式的解析基类
 */
@interface MamaNetworkBaseResponse : NSObject

/** 错误信息 */
@property (nonatomic, copy, nullable) NSString *msg;

/** 状态码 */
@property (nonatomic, assign) NSInteger code;

/** 源数据 */
@property (nonatomic, strong, nullable) id responseJSONObject;


@end

NS_ASSUME_NONNULL_END
