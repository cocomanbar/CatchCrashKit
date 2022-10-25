//
//  MamaNetworkDomainAgent.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/18.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MamaNetworkDomainCompleteBlock)(void);

/// app类型
typedef NS_ENUM(NSInteger, MMWNetworkSource){
    MMWNetworkSourceMaMaWang = 1,           // 妈妈网
    MMWNetworkSourcePregnancyHelper,        // 孕育管家
    MMWNetworkSourceGuangZhouQuan,          // 广州圈
    MMWNetworkSourceGZMaMaWang,             // 广州妈妈网
    MMWNetworkSourceRecord,                 // 亲子记
};

/// 用户信息
@protocol MMWNetworkSourceUserInfoProtocol <NSObject>

@required
/**
 *  基本的参数：
 *      城市：KEY = `cityname`
 */
- (NSDictionary *)paramsFromSouceAppAppliedToNetworkDomainManager;

@end

@interface MamaNetworkDomainAgent : NSObject

/**
 *  是否开启 Domain 检查替换
 */
+ (void)setEnableDomainSwitch:(BOOL)enableDomain;
+ (BOOL)domainSwitchEnable;

/**
 *  设置Domain请求的默认时间
 */
+ (void)setDefaultTimeIntervalOnlyForDomainManager:(NSTimeInterval)timeInterval;

/**
 *  设置独立的ua给DomainManager
 */
+ (void)setDefaultUserAgentOnlyForDomainManager:(NSString * _Nullable)userAgent;

/**
 *  设置url的UUID cookie
 */
+ (void)setupUUIDCookieOfURL:(NSURL * _Nullable)url;

/**
 *  域名是否需要替换
 */
+ (BOOL)shouldReplaceDomain:(NSString * _Nullable)domain;

/**
 *  domain对应的ipList
 */
+ (NSArray *)ipListOfDomain:(NSString * _Nullable)domain;

/**
 *  domian对应的ip列表 array是否有count以及是否过期
 */
+ (BOOL)isIPListExistsAndNotExpiredOfDomain:(NSString * _Nullable)domain;

/**
 *  保存域名是否需要替换ip标记
 */
+ (void)saveDomainShouldReplaceMark:(BOOL)domainShouldReplaceMark ofDomain:(NSString * _Nullable)domain;

/**
 *  doamin需要替换为的ip字典
 */
+ (NSDictionary *)ipDictOfReplacedDomain:(NSString * _Nullable)domain;

/**
 *  删除无效的替换域名
 */
+ (void)deleteInvalidIPDict:(NSDictionary * _Nullable)invalidIPDict fromIPListOfDomain:(NSString * _Nullable)domain;




/**
 *  请求北京域名对应的ip（应用进入前台时调用，可以及时更新Server的ip）
 */
+ (void)requestNetworkIPsWithAppType:(MMWNetworkSource)appType
                       userInfoClass:(Class<MMWNetworkSourceUserInfoProtocol> _Nonnull)userInfoClass;

/**
 *  请求domain对应的iplist
 */
+ (void)requestNetworkIPsAtDomain:(NSString * _Nullable)domain
                     successBlock:(MamaNetworkDomainCompleteBlock _Nullable)successBlock
                     failureBlock:(MamaNetworkDomainCompleteBlock _Nullable)failureBlock;




@end

NS_ASSUME_NONNULL_END
