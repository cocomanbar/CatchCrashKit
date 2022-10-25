//
//  MamaNetworkBaseRequest.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MamaNetworkDataResponse.h"
#import "MamaNetworkBaseTokenResponse.h"
#import "MamaNetworkBaseErrorResponse.h"
#import "MamaNetworkDefine.h"
#import "MamaNetworkCache.h"
#import "MamaNetworkComponentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MamaNetworkBaseRequest : NSObject

@property (nonatomic, copy, nullable) MamaRequestCacheBlock cacheBlock;
@property (nonatomic, copy, nullable) MamaRequestSuccessBlock successBlock;
@property (nonatomic, copy, nullable) MamaRequestFailureBlock failureBlock;
@property (nonatomic, copy, nullable) MamaRequestNetErrorBlock netErrorBlock;

/** 添加插件 */
- (void)addComponent:(id<MamaNetworkComponentProtocol> _Nullable)component;

/** 发起网络请求带回调，内部自动调【start】 */
- (void)startWithSuccess:(MamaRequestSuccessBlock _Nullable)successBlock
                 failure:(MamaRequestFailureBlock _Nullable)failureBlock
                netError:(MamaRequestNetErrorBlock _Nullable)netErrorBlock;

- (void)startWithCache:(MamaRequestCacheBlock _Nullable)cacheBlock
               success:(MamaRequestSuccessBlock _Nullable)successBlock
               failure:(MamaRequestFailureBlock _Nullable)failureBlock
              netError:(MamaRequestNetErrorBlock _Nullable)netErrorBlock;

/** 发起网络请求 */
- (void)start;

/** 是否正在网络请求，属性方式可用 */
- (BOOL)isExecuting;

/** 取消网络请求，属性方式可用 */
- (void)cancel;

#pragma mark - init request

/** 请求方法类型 */
@property (nonatomic, assign) MamaRequestMethod requestMethod;

/** 服务器地址及公共路径 (例如：https://www.mama.cn) */
@property (nonatomic, copy, nullable) NSString *baseURI;

/** 请求访问Path路径 (例如：/api/detail/list) */
@property (nonatomic, copy, nullable) NSString *requestURI;

/** mock地址：如果赋值了，那么请求就会使用这个url（如：http://yapi.mama.cn/mock/222/api/user/receive_like_list） */
@property (nonatomic, copy, nullable) NSString *mockURI;

/** 请求参数加密的密钥，默认是普通加密KEY，不同的接口需要可以在实现api子类时重新赋值（服务器给的字符串） */
/** 例如：MMIT-API，PUSHTOKEN-API，等重新override  */
@property (nonatomic ,copy, nullable) NSString *requestSecureKey;

/** 请求参数 */
@property (nonatomic, copy, nullable) NSDictionary *requestParameter;

/** POST请求的body，在POST下优先级比requestParameter属性高 */
@property (nonatomic, copy, nullable) NSData *body;

/** 追加请求头 */
@property (nonatomic, copy, nullable) NSDictionary *httpHeaderField;

/** 发起请求前fix一次请求参数 */
@property (nonatomic, copy, nullable) NSDictionary *(^FixRequestParameter)(NSMutableDictionary *requestParameter);

/** 解析类，建议业务通过继承出派生类 */
/** 默认 MamaNetworkBaseResponse/MamaNetworkBaseTokenResponse */
@property (nonatomic, assign) Class modelClass;

/** 解析码code，默认：0 */
@property (nonatomic, assign) NSInteger requestCode;

/** 请求时间，默认：15s */
@property (nonatomic, assign) NSTimeInterval timeInterval;

/** 上传文件或图片 */
@property (nonatomic, copy, nullable) NSString *fileKey;     //文件字段的Key
@property (nonatomic, copy, nullable) NSString *fileName;    //文件字段的名称（需要带上扩展名） 例如字符串"iosIphone.jpeg"
@property (nonatomic, copy, nullable) NSData *data;          //文件的data

/** 本次请求会不会发生ip重试，global开启后有此属性设置有效，默认 true */
@property (nonatomic, assign) BOOL enableDomain;

#pragma mark - request strategy

/** 网络请求释放策略 (默认 MamaNetworkReleaseStrategyWhenRequestDealloc) */
@property (nonatomic, assign) MamaNetworkReleaseStrategy releaseStrategy;

/** 重复网络请求处理策略 (默认 MamaNetworkRepeatStrategyAllAllowed) */
@property (nonatomic, assign) MamaNetworkRepeatStrategy repeatStrategy;

/** 网络缓存回调时机处理策略 (默认 MamaNetworkCacheBackModeRequestStart) */
@property (nonatomic, assign) MamaNetworkCacheBackMode cacheBackStrategy;

#pragma mark - cache

/** 此API是否启动缓存程序 (默认 MamaNetworkCacheWriteModeNone) 外置该属性是为了杜绝每次生成[MamaNetworkCache class]实例，毕竟缓存很少用*/
@property (nonatomic, assign) MamaNetworkCacheMode cacheMode;

/** 缓存处理器 */
@property (nonatomic, strong, readonly, nullable) MamaNetworkCache *cacheHandler;

/** 缓存键值过滤器，默认不过滤任何key */
@property (nonatomic ,strong, nullable) NSArray *cacheIgnoreKeysArray;

#pragma mark - plugins

@property (nonatomic, strong, nullable) NSMutableArray <id<MamaNetworkComponentProtocol>>*components;

#pragma mark - task

@property (nonatomic, strong, nullable) NSURLSessionTask *dataTask;

@property (nonatomic, strong, nullable) id responseJsonObject;

@property (nonatomic, strong, nullable) NSError *error;

@end

#pragma mark - override category

@interface MamaNetworkBaseRequest (PreprocessRequest)

/** 预处理请求参数, 返回处理后的请求参数 */
- (NSDictionary * _Nonnull)mamanetwork_preprocessParameter:(NSDictionary * _Nullable)parameter;

/** 在构造请求task的时候，发现没有ua向业务层索要一个ua */
- (NSString * _Nullable)mamanetwork_preprocessUserAgentWhenNotFound;

/// 每个APP必须传入的参数,子类重写
+ (NSDictionary * _Nullable)necessaryParameters;

@end

NS_ASSUME_NONNULL_END
