//
//  MamaNetworkBaseTokenResponse.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/23.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//  接口数据载体解析类：TOKEN
//  初始化接口请求类时，直接传继承于此类的子类方便做初始化数据
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface MamaNetworkBaseTokenErrorResponse : NSObject

@property (nonatomic, assign) NSInteger errNo;
@property (nonatomic, copy, nullable) NSString *msg;

@end

/**
 *  TOKEN 验签方式的解析基类
 */
@interface MamaNetworkBaseTokenResponse : NSObject

@property (nonatomic ,strong, nullable) MamaNetworkBaseTokenErrorResponse *errmsg;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, strong, nullable) id responseJSONObject;

//继承扩展data对象，验证token的方式有些是data/object/list/貌似都有，这里就不支持了，交由业务方继承扩展..

@end

NS_ASSUME_NONNULL_END
