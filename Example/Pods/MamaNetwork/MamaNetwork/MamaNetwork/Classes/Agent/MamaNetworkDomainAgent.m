//
//  MamaNetworkDomainAgent.m
//  MamaNetwork
//
//  Created by tanxl on 2022/5/18.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkDomainAgent.h"
#import "MamaNetworkParams.h"
#import "NSString+MamaNetwork.h"

static BOOL _mmwNetworkEnableDomainSwitch = NO;
static NSTimeInterval _defaultTimeInterval = 15;
static NSString *_mmwNetworkDomainUA = @"";
static MMWNetworkSource _mmwNetworkSource = MMWNetworkSourcePregnancyHelper;
static Class<MMWNetworkSourceUserInfoProtocol> _mmwNetworkDomainUserInfoClass;

static NSString *_mmwNetworkBeijingServerIP;
static NSString *const mmwNetworkBeiJingDefaultIP = @"118.186.65.144"; // 北京机房默认ip

typedef void(^MamaNetworkDomainDataBackBlock)(NSURLResponse *response, NSData *data, NSError *error);

@implementation MamaNetworkDomainAgent

/**
 *  是否开启 Domain 检查
 */
+ (void)setEnableDomainSwitch:(BOOL)enableDomain {
    _mmwNetworkEnableDomainSwitch = enableDomain;
}

+ (BOOL)domainSwitchEnable {
    return _mmwNetworkEnableDomainSwitch;
}

/**
 *  设置Domain请求的默认时间
 */
+ (void)setDefaultTimeIntervalOnlyForDomainManager:(NSTimeInterval)timeInterval {
    _defaultTimeInterval = timeInterval;
}

/**
 *  请求北京域名对应的ip（应用进入前台时调用，可以及时更新Server的ip）
 */
+ (void)requestNetworkIPsWithAppType:(MMWNetworkSource)appType
                       userInfoClass:(Class<MMWNetworkSourceUserInfoProtocol>)userInfoClass
{
    _mmwNetworkSource = appType;
    _mmwNetworkDomainUserInfoClass = userInfoClass;
}

/**
 *  设置独立的ua给DomainManager
 */
+ (void)setDefaultUserAgentOnlyForDomainManager:(NSString *)userAgent {
    _mmwNetworkDomainUA = userAgent;
}

/**
 *  设置url的UUID cookie
 */
+ (void)setupUUIDCookieOfURL:(NSURL *)url{
    if (!url) {
        return;
    }
    if (![url.absoluteString hasPrefix:@"http://"] && ![url.absoluteString hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",url.absoluteString]];
    }
    NSString *cookieName = @"UUID";
    NSString *str = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:cookieName];
    str = str ? str : @"";
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
    [cookieProperties setObject:str forKey:NSHTTPCookieValue];
    [cookieProperties setObject:[url host] forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:[url host] forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieProperties setObject:@"0.2.0" forKey:NSHTTPCookieVersion];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

/**
 *  请求domain对应的iplist
 */
+ (void)requestNetworkIPsAtDomain:(NSString *)domain
                     successBlock:(MamaNetworkDomainCompleteBlock)successBlock
                     failureBlock:(MamaNetworkDomainCompleteBlock)failureBlock
{
    if (!domain.length) {
        if (failureBlock) {
            failureBlock();
        }
        return;
    }

    // 请求参数
    NSMutableDictionary *parametersDict = [self parametersDictionary];
    [parametersDict setObject:@"domain" forKey:@"type"]; // 要求返回指定域名列表
    [parametersDict setObject:domain forKey:@"p"]; // 需要解释的项目，当 type=domain 时, 必须传这个参数
    
    // 组合url并发起请求
    NSString *beiJingDomain = @"https://d.bjmama.net/s2.php";
    NSString *urlString = [MamaNetworkParams completeUrlForGet:[parametersDict copy] withURLPrefix:beiJingDomain withCompare:false];
    [self sendRequestWithURLString:urlString isNeedSetHost:NO hostDomain:@"d.bjmama.net" headParam:nil requestDataBackBlock:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSString *beiJingIP = _mmwNetworkBeijingServerIP;
            if (!beiJingIP.length) {
                beiJingIP = mmwNetworkBeiJingDefaultIP;
            }
            // ip不支持https因此替换使用ip请求时使用http
            NSString *newURLString = [urlString stringByReplacingOccurrencesOfString:@"https://d.bjmama.net" withString:[NSString stringWithFormat:@"http://%@", beiJingIP]];
            // 从北京机房对应的IP地址请求
            [self sendRequestWithURLString:newURLString isNeedSetHost:YES hostDomain:@"d.bjmama.net" headParam:nil requestDataBackBlock:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (error) {
                    if (failureBlock) {
                        failureBlock();
                    }
                }else {
                    [self dealWithReturnData:data ofDomain:domain successBlock:successBlock failureBlock:failureBlock];
                }
            }];
        }else {
            [self dealWithReturnData:data ofDomain:domain successBlock:successBlock failureBlock:failureBlock];
        }
    }];
}

/**
 *  域名是否需要替换
 */
+ (BOOL)shouldReplaceDomain:(NSString *)domain {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldReplace = [userDefaults boolForKey:[NSString stringWithFormat:@"%@-domainShouldReplaceMarkKey", domain]];
    if (shouldReplace) {
        BOOL isExpired = [self isDomainShouldReplaceMarkExpiredOfDomain:domain];
        if (isExpired) {
            [userDefaults setBool:NO forKey:[NSString stringWithFormat:@"%@-domainShouldReplaceMarkKey", domain]];
            [userDefaults synchronize];
            return NO;
        }else {
            return YES;
        }
    }else {
        return NO;
    }
}

/**
 *  domain是否需要替换ip标记 是否过期
 */
+ (BOOL)isDomainShouldReplaceMarkExpiredOfDomain:(NSString *)domain
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger domainShouldReplaceMarkTimeInterval = [[userDefaults objectForKey:[NSString stringWithFormat:@"%@-domainShouldReplaceMarkExpiredTimeKey", domain]] integerValue];
    NSInteger currentTimeInterval = (NSInteger)[[NSDate date] timeIntervalSince1970];
    return currentTimeInterval > domainShouldReplaceMarkTimeInterval;
}

/**
 *  保存域名是否需要替换ip标记
 */
+ (void)saveDomainShouldReplaceMark:(BOOL)domainShouldReplaceMark ofDomain:(NSString *)domain {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setBool:domainShouldReplaceMark forKey:[NSString stringWithFormat:@"%@-domainShouldReplaceMarkKey", domain]];
    
    NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSInteger expireTimeInterval = (NSInteger)(currentTimeInterval + 5 * 60);
    [userDefaults setObject:@(expireTimeInterval) forKey:[NSString stringWithFormat:@"%@-domainShouldReplaceMarkExpiredTimeKey", domain]];
    
    [userDefaults synchronize];
}

/**
 *  domain对应的ipList
 */
+ (NSArray *)ipListOfDomain:(NSString *)domain {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *ipList = [userDefaults objectForKey:[NSString stringWithFormat:@"%@-ipListKey", domain]];
    if ([ipList isKindOfClass:[NSArray class]]) {
        return ipList;
    } else {
        return [NSArray array];
    }
}

/**
 *  domian对应的ip列表 array是否有count以及是否过期
 */
+ (BOOL)isIPListExistsAndNotExpiredOfDomain:(NSString *)domain {
    BOOL isIPlistExists = NO;
    NSArray *ipList = [self ipListOfDomain:domain];
    if (ipList.count) {
        BOOL isExpired = [self isIPListExpiredOfDomain:domain];
        if (isExpired) {
            isIPlistExists = NO;
        }else {
            isIPlistExists = YES;
        }
    }
    return isIPlistExists;
}

// ipList是否过期（ipList过期不要清空，先留着，以防从接口获取新ipList失败时，可以用旧的来替换域名）
+ (BOOL)isIPListExpiredOfDomain:(NSString *)domain
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger ipListExpiredTimeInterval = [[userDefaults objectForKey:[NSString stringWithFormat:@"%@-ipListExpireTimeKey", domain]] integerValue];
    NSInteger currentTimeInterval = (NSInteger)[[NSDate date] timeIntervalSince1970];
    return currentTimeInterval > ipListExpiredTimeInterval;
}

/**
 *  doamin需要替换为的ip字典
 */
+ (NSDictionary *)ipDictOfReplacedDomain:(NSString *)domain {
    NSDictionary *ipDict = nil;
    NSArray *ipList = [self ipListOfDomain:domain];
    if (ipList.count) {
        ipDict = ipList[0];
    }
    if ([ipDict isKindOfClass:[NSDictionary class]]) {
        return ipDict;
    } else {
        return [NSDictionary dictionary];
    }
}

/**
 *  删除无效的替换域名
 */
+ (void)deleteInvalidIPDict:(NSDictionary *)invalidIPDict fromIPListOfDomain:(NSString *)domain {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *ipList = [self ipListOfDomain:domain];
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:ipList];
    [tempArray removeObject:invalidIPDict];
    [userDefaults setObject:tempArray forKey:[NSString stringWithFormat:@"%@-ipListKey", domain]];
    [userDefaults synchronize];
}

#pragma mark - Domain请求管理发送请求及返回数据处理

+ (void)sendRequestWithURLString:(NSString *)urlString
                   isNeedSetHost:(BOOL)isNeedSetHost
                      hostDomain:(NSString *)hostDomain
                       headParam:(NSDictionary *)headParam
            requestDataBackBlock:(MamaNetworkDomainDataBackBlock)requestDataBackBlock
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    if (isNeedSetHost) { // 替换为ip访问时需要设置header的Host
        [request setValue:hostDomain forHTTPHeaderField:@"Host"];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    [request setURL:url];
    request.timeoutInterval = _defaultTimeInterval;
    if ([headParam isKindOfClass:[NSDictionary class]]) {
        [headParam enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    // 设置User-Agent
    [request setValue:[MamaNetworkDomainAgent userAgent] forHTTPHeaderField:@"User-Agent"];
    
    // 设置一些cookies
    [MamaNetworkDomainAgent setupUUIDCookieOfURL:url];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (requestDataBackBlock) {
                requestDataBackBlock(response, data, error);
            }
        });
    }];
    
    // 启动任务
    [task resume];
}

+ (void)dealWithReturnData:(NSData *)data
                  ofDomain:(NSString *)domain
              successBlock:(MamaNetworkDomainCompleteBlock)successBlock
              failureBlock:(MamaNetworkDomainCompleteBlock)failureBlock
{
    NSError *jsonError = nil;
    NSDictionary *domainIPListDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
    if (jsonError || ![domainIPListDict isKindOfClass:[NSDictionary class]]) {
        if (failureBlock) {
            failureBlock();
        }
        return;
    }
    int code = [domainIPListDict[@"code"] intValue];
    NSArray *ipList = domainIPListDict[@"data"];
    if (code != 0 || [ipList isKindOfClass:NSArray.class]) {
        if (failureBlock) {
            failureBlock();
        }
        return;
    }
    
    // 保存doamin对应的ipList
    BOOL isSaveSucceed = [MamaNetworkDomainAgent saveIPList:ipList ofDomain:domain];
    if (isSaveSucceed) {
        if (successBlock) {
            successBlock();
        }
    }else {
        if (failureBlock) {
            failureBlock();
        }
    }
}

/**
 *  保存domain对应的ip列表，并设置过期时间为5分钟
 *
 *  @param ipList ip列表
 [
 {
 "remote_add": "118.186.65.167",
 "set_host": 1
 },
 {
 "remote_add": "mapi2.mama.cn",
 "set_host": 0
 }
 ]
 *  @param domain 域名
 */
+ (BOOL)saveIPList:(NSArray *)ipList ofDomain:(NSString *)domain
{
    if (![ipList isKindOfClass:[NSArray class]] || !ipList.count) {
        return NO;
    }
    
    // 将ipList的域名排到前面（后续替换时先用域名替换，再用ip替换）
    NSArray *descendingIPList = [self descendingIPListWithOriginalIPList:ipList];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:descendingIPList forKey:[NSString stringWithFormat:@"%@-ipListKey", domain]];
    
    NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
    NSInteger expireTimeInterval = (NSInteger)(currentTimeInterval + 5 * 60);
    [userDefaults setObject:@(expireTimeInterval) forKey:[NSString stringWithFormat:@"%@-ipListExpireTimeKey", domain]];
    
    BOOL isSaveSucceed = [userDefaults synchronize];
    return isSaveSucceed;
}

+ (NSArray *)descendingIPListWithOriginalIPList:(NSArray *)originalIPList
{
    NSMutableArray *replaceDomainList = [NSMutableArray array];
    for (NSDictionary *dict in originalIPList) {
        NSString *urlPath = dict[@"remote_add"];
        if ([urlPath mamaNetwork_isContainsEnglishCharacter]) { // 是域名
            [replaceDomainList addObject:dict];
        }
    }
    
    if (!replaceDomainList.count) {
        return originalIPList;
    }
    
    NSMutableArray *originalIPListMutable = [NSMutableArray arrayWithArray:originalIPList];
    [originalIPListMutable removeObjectsInArray:replaceDomainList];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, replaceDomainList.count)];
    [originalIPListMutable insertObjects:replaceDomainList atIndexes:indexSet];
    
    return originalIPListMutable;
}

#pragma mark - Private

+ (NSString *)userAgent{
    if (_mmwNetworkDomainUA.length) {
        return _mmwNetworkDomainUA;
    }
    NSString *userAgent = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:@"USERAGENT"];
    if ([userAgent isKindOfClass:NSString.class]) {
        return userAgent;
    }
    return @"";
}

+ (NSMutableDictionary *)parametersDictionary
{
    NSMutableDictionary *parametersDict = [NSMutableDictionary dictionary];
    NSString *app = @"";
    switch (_mmwNetworkSource) {
        case MMWNetworkSourceMaMaWang:
            app = @"mmq";
            break;
        case MMWNetworkSourcePregnancyHelper:
            app = @"pt";
            break;
        case MMWNetworkSourceGuangZhouQuan:
            app = @"gzq";
            break;
        case MMWNetworkSourceGZMaMaWang:
            app = @"gzm";
            break;
        case MMWNetworkSourceRecord:
            app = @"record";
            break;
    }
    [parametersDict setObject:app forKey:@"app"]; // app标识
    
    if (_mmwNetworkDomainUserInfoClass &&
        [(id)_mmwNetworkDomainUserInfoClass respondsToSelector:@selector(paramsFromSouceAppAppliedToNetworkDomainManager)]) {
        NSDictionary *sourceParams = [(id)_mmwNetworkDomainUserInfoClass paramsFromSouceAppAppliedToNetworkDomainManager];
        if ([sourceParams isKindOfClass:NSDictionary.class]) {
            // 城市是已知必须的：客户端没收集到默认给 @"0"，历史这样子。
            #ifdef DEBUG
            NSAssert(([sourceParams objectForKey:@"cityname"]), @"城市是已知必须的：客户端没收集到默认给 @\"0\"，历史这样子");
            #endif
            [parametersDict addEntriesFromDictionary:sourceParams];
        }
    }
    
    MMWMobileOperatorsType mobileOperatorsType = [MamaNetworkParams mobileOperatorsType];
    NSString *carrierCode = @"0";
    switch (mobileOperatorsType) {
        case MMWMobileOperatorsTypeChinaMobile:
            carrierCode = @"1";
            break;
        case MMWMobileOperatorsTypeChinaUnicom:
            carrierCode = @"2";
            break;
        case MMWMobileOperatorsTypeChinaTelecom:
            carrierCode = @"3";
            break;
        case MMWMobileOperatorsTypeUnknow:
            carrierCode = @"0";
            break;
    }
    [parametersDict setObject:carrierCode forKey:@"isp"]; // 运营商信息
    
    [parametersDict setObject:@"2" forKey:@"source"]; // source：来源 2表示iOS
    
    NSString *version = [MamaNetworkParams systemVersion];
    if (version) {
        [parametersDict setObject:version forKey:@"ver"]; // app版本
    }
    
    return parametersDict;
}

@end
