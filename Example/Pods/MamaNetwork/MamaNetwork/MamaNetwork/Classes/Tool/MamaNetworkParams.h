//
//  MamaNetworkParams.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/17.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//  参数整合和加密类
//

#import <Foundation/Foundation.h>
#import "NSMutableDictionary+MamaNetwork.h"

// 获取网络ip
#define MAMAIP                          [MamaNetworkParams getIPAddress]

NS_ASSUME_NONNULL_BEGIN

/// 区别token和sign的验签方式，后台默认是token，前端传sign和appkey参数则验证sign，否则返回token格式数据。
typedef NS_ENUM(NSInteger, MamaParamsSomeKey){
    MAMAPARAMS_TOBUY_SECURE_KEY     =1, ///
    MAMAPARAMS_PUSH_SECURE_KEY      =2, ///
    MAMAPARAMS_IMAGE_SECURE_KEY     =3, ///
    MAMAPARAMS_USERAVTAR_SECURE_KEY =4, ///
    MAMAPARAMS_MQTT_SECURE_KEY      =5, ///
    MAMAPARAMS_STATIS1_SECURE_KEY   =6, ///
};

/// 运营商类型
typedef NS_ENUM(NSInteger, MMWMobileOperatorsType){
    MMWMobileOperatorsTypeUnknow = 0,   /// 未知
    MMWMobileOperatorsTypeChinaMobile,  /// 中国移动
    MMWMobileOperatorsTypeChinaUnicom,  /// 中国联通
    MMWMobileOperatorsTypeChinaTelecom, /// 中国电信
};

@interface MamaNetworkParams : NSObject

#pragma mark - 基本的参数和获取
/**
 加密kKEY
 
 @return return value description
 */
+ (NSString * _Nullable)secureKeyFromKey:(MamaParamsSomeKey)key;

/**
 系统参数
 包含systemExtParams
 
 @return return value description
 */
+ (NSDictionary * _Nullable)systemParams;

/**
 系统外区别于工程额外的参数
 
 @return return value description
 */
+ (NSDictionary * _Nullable)systemExtParams;


/**
 更新服务器系统时间差
 
 @param timeInterval timeInterval description
 */
+ (void)setServiceTimeInterval:(NSTimeInterval)timeInterval;

/**
 获取系统时间差
 **/
+ (NSInteger)getServiceTimeInterval;

#pragma mark - 加密方式
/**
 MD5加密参数，papi_token
 
 @param paramDict 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString * _Nullable)appendParmas_PapiToken:(NSDictionary * _Nonnull)paramDict sk:(NSString * _Nonnull)secureKey;


/**
 MD5加密参数，papi_sign
 
 @param param 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString * _Nullable)appendParmas_PapiSign:(NSDictionary * _Nonnull)param sk:(NSString * _Nonnull)secureKey;


/**
 MD5加密参数，mapi_sign
 
 @param paramDict 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString * _Nullable)appendParmas_MapiToken:(NSDictionary * _Nonnull)paramDict sk:(NSString * _Nonnull)secureKey;

/**
 MD5加密参数，papi_sign
 
 @param paramDict 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString * _Nullable)appendSearchUserToken:(NSDictionary * _Nonnull)paramDict withSecureKey:(NSString * _Nonnull)secureKey;

/**
 完整的URL路径
 
 @param paramDict 参数
 @param urlPrefix 前面路径(例如:https://www.baidu.com/ipa/haha/)
 @param isCompare 是否排序，无排序拼接or按key升序拼接
 @return return value description
 */
+ (NSString * _Nullable)completeUrlForGet:(NSDictionary * _Nonnull)paramDict withURLPrefix:(NSString * _Nullable)urlPrefix withCompare:(BOOL)isCompare;

/**
 针对旧版已登陆用户，如果传过来的是hash，则需要多加一个参数；如果传过来的是新版app_auth_token则不需要
 
 @param hash hash description
 @param key key description
 @param dict dict description
 */
+ (void)setDictWithHash:(NSString * _Nonnull)hash key:(NSString * _Nonnull)key dict:(NSMutableDictionary * _Nonnull)dict;


#pragma mark - 网络参数

/**
 获取手机的网络的ip地址
 
 @return ip地址
 */
+ (NSString * _Nullable)getIPAddress;

/**
 *  运营商类型名称
 */
+ (NSString * _Nullable)carrierName;

/**
 *  运营商类型枚举
 */
+ (MMWMobileOperatorsType)mobileOperatorsType;

/**
 *  手机型号 DeviceName
 */
+ (NSString * _Nullable)deviceName;

/**
 *  系统版本
 */
+ (NSString * _Nullable)systemVersion;

@end

NS_ASSUME_NONNULL_END
