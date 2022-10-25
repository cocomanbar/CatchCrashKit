//
//  MamaNetworkParams.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/17.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkParams.h"

#import "OpenUDID.h"
#import <AdSupport/AdSupport.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>
#import "sys/utsname.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "MamaNetworkStatus.h"
#import "NSString+MamaNetwork.h"

@implementation MamaNetworkParams
static NSString *serviceTimeSpace = nil;
static NSString *kServiceTimeUserDefault = @"kServiceTimeUserDefault"; // 服务器时间差key

/**
 加密kKEY
 
 @return return value description
 */
+ (NSString *)secureKeyFromKey:(MamaParamsSomeKey)key{
    switch (key) {
        case MAMAPARAMS_TOBUY_SECURE_KEY: return @"=SCFDAS%$vcnjicyCHU34098!+2d36MFNI=";
        case MAMAPARAMS_PUSH_SECURE_KEY: return @"%3y@.S9-XnUg@~7Y";
        case MAMAPARAMS_MQTT_SECURE_KEY: return @"p?US?2EPu5RUChuwA@2?rEp!br6KeJu+";
        case MAMAPARAMS_IMAGE_SECURE_KEY: return @"[$dD9[8TXY$].WxV2p.EdfJwb8=Jwf";
        case MAMAPARAMS_STATIS1_SECURE_KEY: return @"Zi-Qft-asF_PL_FvLfupb2vP__ke";
        case MAMAPARAMS_USERAVTAR_SECURE_KEY: return @"-N%IKvc9kycH1oNa)rl]2yJCUzC0^h";
    }
}

/**
 系统参数
 
 @return return value description
 */
+ (NSDictionary *)systemParams
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    //version
    NSString *version = [NSString mamaNetwork_appVersion];
    [dic network_setObject:version forKey:@"version"];
    //appkey
    NSString *appkey = @"pt_iphone";
    [dic network_setObject:appkey forKey:@"appkey"];
    //device_id
    NSString *device_id = [OpenUDID value]?:@"";
    [dic network_setObject:device_id forKey:@"open_mmid"];
    //source
    NSString *source = @"2";
    [dic network_setObject:source forKey:@"source"];
    //t
    NSString *t;
    // 如果时间差没值，尝试从UserDefaults获取，有可能启动过快，接口还没返回
    if (!serviceTimeSpace) {
        serviceTimeSpace = [[NSUserDefaults standardUserDefaults] objectForKey:kServiceTimeUserDefault];
    }
    if (serviceTimeSpace) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval appTime = now + [serviceTimeSpace longLongValue];
        t = [NSString stringWithFormat:@"%ld", (long)appTime];
    } else {
        t = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    }
    [dic network_setObject:t forKey:@"t"];
    
    //渠道标识
    NSString *statistics_app_channel = @"AppStore";
    [dic network_setObject:statistics_app_channel forKey:@"statistics_app_channel"];

    //来源
    NSString *statistics_app_source = @"pt_iphone";
    [dic network_setObject:statistics_app_source forKey:@"statistics_app_source"];
    //拼接额外参数
    [dic addEntriesFromDictionary:[self systemExtParams]];
    return dic;
}

/**
 系统外区别于工程额外的参数
 
 @return return value description
 */
+ (NSDictionary *)systemExtParams
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];

    //手机型号
    NSString *statistics_device_model = [MamaNetworkParams deviceName];
    [dic network_setObject:statistics_device_model forKey:@"statistics_device_model"];
    //系统版本
    NSString *statistics_os_version = [MamaNetworkParams systemVersion];
    [dic network_setObject:statistics_os_version  forKey:@"statistics_os_version"];
    //网络环境
    NSString *statistics_network_type = [MamaNetworkStatus sharedManager].networkStatusString;
    if ([statistics_network_type isEqualToString:@"0"] || !statistics_network_type) {
        statistics_network_type = @"unknown";
    }
    [dic network_setObject:statistics_network_type forKey:@"statistics_network_type"];
    // idfa
    NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    [dic network_setObject:idfa forKey:@"statistics_ios_idfa"];

    
    //运营商
    NSString *statistics_carrier = @"Unknown";
    MMWMobileOperatorsType mobileOperatorsType = [MamaNetworkParams mobileOperatorsType];
    switch (mobileOperatorsType) {
        case MMWMobileOperatorsTypeUnknow:
            statistics_carrier = @"Unknown";
            break;
        case MMWMobileOperatorsTypeChinaMobile:
            statistics_carrier = @"ChinaMobile";
            break;
        case MMWMobileOperatorsTypeChinaUnicom:
            statistics_carrier = @"ChinaUnicom";
            break;
        case MMWMobileOperatorsTypeChinaTelecom:
            statistics_carrier = @"ChinaTelecom";
            break;
    }
    [dic network_setObject:statistics_carrier forKey:@"statistics_carrier"];
    //经纬度
    NSString *latitude = [NSString stringWithFormat:@"%g", [[NSUserDefaults standardUserDefaults] floatForKey:@"PHLatitudeUserDefaultsKey"]];
    NSString *longitude = [NSString stringWithFormat:@"%g", [[NSUserDefaults standardUserDefaults] floatForKey:@"PHLongitudeUserDefaultsKey"]];
    [dic network_setObject:latitude forKey:@"statistics_latitude"];
    [dic network_setObject:longitude forKey:@"statistics_longitude"];
    
    NSString *idfa_backup = [[NSUserDefaults standardUserDefaults] objectForKey:@"idfa_backup"];
    NSString *idfa_backup_version = [[NSUserDefaults standardUserDefaults] objectForKey:@"idfa_backup_version"];
        
    [dic network_setObject:idfa_backup forKey:@"idfa_backup"];
    [dic network_setObject:idfa_backup_version forKey:@"idfa_backup_version"];
    
    return dic;
}

/**
 更新服务器系统时间差
 
 @param timeInterval timeInterval description
 */
+ (void)setServiceTimeInterval:(NSTimeInterval)timeInterval{
    serviceTimeSpace = [NSString stringWithFormat:@"%ld",(long)timeInterval];
    // 保存到UserDefaults，方便下次启动app使用
    [[NSUserDefaults standardUserDefaults] setObject:serviceTimeSpace forKey:kServiceTimeUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 获取系统时间差
 **/
+ (NSInteger)getServiceTimeInterval{
    return [serviceTimeSpace integerValue];
}

#pragma mark -

/**
 MD5加密参数，papi_token
 
 @param paramDict 加密数据
 @param secureKey 加密key
 @return return value description
 */
+ (NSString *)appendParmas_PapiToken:(NSDictionary *)paramDict sk:(NSString *)secureKey{
    NSMutableString *token = [NSMutableString stringWithCapacity:0];
    NSArray *keys = [paramDict allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        NSString *keyValue = [paramDict objectForKey:key];
        if ([keyValue isKindOfClass:[NSString class]] && [keyValue isEqualToString:@""]) {
            //papi值为空就不传了，而mipa是传的。
            continue;
        }
        //生成token需要先对值做urlencode
        NSString * tmp = [NSString stringWithFormat:@"%@%@",key,keyValue];
        [token appendString:tmp];
    }
    NSString * tokenMd5 = [NSString stringWithFormat:@"%@%@%@",secureKey,token,secureKey];
    NSString * rs = [tokenMd5 mamaNetwork_md5];
    return rs;
}

/**
 MD5加密参数，papi_sign
 
 @param param 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString *)appendParmas_PapiSign:(NSDictionary *)param sk:(NSString *)secureKey{
    NSMutableString *sign = [NSMutableString string];
    NSArray *keys = [param allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        if ([key isEqualToString:@"sign"]) {
            continue;
        }
        NSString *keyValue = [NSString stringWithFormat:@"%@",[param valueForKey:key]];
        NSString *keyValueEncode = [keyValue mamaNetwork_urlEncode];
        [sign appendFormat:@"%@%@", key, keyValueEncode];
    }
    [sign appendString:secureKey];
    return [[sign mamaNetwork_md5] uppercaseString];
}

/**
 MD5加密参数，papi_sign
 
 @param paramDict 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString *)appendSearchUserToken:(NSDictionary *)paramDict withSecureKey:(NSString *)secureKey{
    NSString *token = @"";
    NSArray *keys = [paramDict allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        NSString *keyValue = [paramDict objectForKey:key];
        token = [NSString stringWithFormat:@"%@%@",token,keyValue];
    }
    token = [NSString stringWithFormat:@"%@%@",token,secureKey];
    token = [token mamaNetwork_md5];
    return  token;
}

/**
 MD5加密参数，mapi_sign
 
 @param paramDict 加密数据
 @param secureKey 接口分配的密钥
 @return return value description
 */
+ (NSString *)appendParmas_MapiToken:(NSDictionary *)paramDict sk:(NSString *)secureKey{
    NSMutableString *token = [NSMutableString stringWithCapacity:0];
    NSArray *keys = [paramDict allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        NSString *keyValue = [paramDict objectForKey:key];
        NSString * tmp = [NSString stringWithFormat:@"%@%@",key,keyValue];
        [token appendString:tmp];
    }
    NSString * tokenMd5 = [NSString stringWithFormat:@"%@%@%@",secureKey,token,secureKey];
    NSString * rs = [tokenMd5 mamaNetwork_md5];
    return rs;
}

/**
 完整的URL路径
 
 @param paramDict 参数
 @param urlPrefix 前面路径(例如:https://www.baidu.com/ipa/haha/)
 @param isCompare 是否排序，无排序拼接or按key升序拼接
 @return return value description
 */
+ (NSString *)completeUrlForGet:(NSDictionary *)paramDict withURLPrefix:(NSString *)urlPrefix withCompare:(BOOL)isCompare{
    NSMutableString *returnStr = nil;
    if (!urlPrefix) {
        returnStr = [NSMutableString string];
    } else {
        if ([urlPrefix isKindOfClass:[NSString class]] && urlPrefix) {
            if ([urlPrefix rangeOfString:@"?"].length) {
                returnStr=[NSMutableString stringWithFormat:@"%@%@",urlPrefix,@"&"];
            } else {
                returnStr=[NSMutableString stringWithFormat:@"%@%@",urlPrefix,@"?"];
            }
        } else {
            returnStr=[NSMutableString stringWithFormat:@""];
        }
    }
    
    NSInteger i = [paramDict.allKeys count];
    NSString * vStr = nil;
    NSArray *keys = [paramDict allKeys];
    if (isCompare) {
        keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    }
    for (NSString *key in keys) {
        i--;
        vStr = nil;
        //如果不是NSString，结束本次循环，执行下一次循环
        if (![[paramDict valueForKey:key] isKindOfClass:[NSString class]]) {
            NSAssert(false, ([NSString stringWithFormat:@"key：%@ -> 对应的value非字符串，请转为字符串，否则不会被接入请求!", key]));
            continue;
        }
        //防止value为NSNumber
        vStr = [NSString stringWithFormat:@"%@",[paramDict valueForKey:key]];
        // 拼接 参数的key-value，并且对value进行encode
        if (i > 0) {
            [returnStr appendFormat:@"%@=%@&",key, [vStr mamaNetwork_urlEncode]];
        }else{
            [returnStr appendFormat:@"%@=%@",key, [vStr mamaNetwork_urlEncode]];
        }
    }
    return returnStr;
}

//针对旧版已登陆用户，如果传过来的是hash，则需要多加一个参数；如果传过来的是新版app_auth_token则不需要
+ (void)setDictWithHash:(NSString *)hash key:(NSString *)key dict:(NSMutableDictionary *)dict
{
    if (hash.length < 8) {
        return;
    }
    NSString *subHash = [hash substringToIndex:8];
    if ([subHash isEqualToString:@"oldHash:"]) {
        //传过来的是hash不是token
        subHash = [hash substringFromIndex:8];
        [dict network_setObject:subHash forKey:key];
        [dict network_setObject:@"hash" forKey:@"app_token_type"];
    } else {
        [dict network_setObject:hash forKey:key];
    }
}

#pragma mark - IP

// 获取手机的网络的ip地址
+ (NSString *)getIPAddress
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0) {
                return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return @"";
}

/**
 *  运营商类型名称
 */
+ (NSString *)carrierName {
    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [telephonyInfo subscriberCellularProvider];
    NSString *currentCarrierName =[carrier carrierName];
    return currentCarrierName;
}

/**
 *  运营商类型枚举
 */
+ (MMWMobileOperatorsType)mobileOperatorsType {
    NSString *currentCarrierName =[self carrierName];
    MMWMobileOperatorsType mobileOperatorsType = MMWMobileOperatorsTypeUnknow;
    if ([currentCarrierName rangeOfString:@"中国移动"].length) {
        mobileOperatorsType = MMWMobileOperatorsTypeChinaMobile;
    }else if ([currentCarrierName rangeOfString:@"中国联通"].length) {
        mobileOperatorsType = MMWMobileOperatorsTypeChinaUnicom;
    }else if ([currentCarrierName rangeOfString:@"中国电信"].length) {
        mobileOperatorsType = MMWMobileOperatorsTypeChinaTelecom;
    }
    return mobileOperatorsType;
}

/**
 *  手机型号 DeviceName
 */
+ (NSString *)deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

/**
 *  系统版本
 */
+ (NSString *)systemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

@end
