//
//  MamaNetworkRequestAgent.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkRequestAgent.h"
#import <pthread/pthread.h>
#import "MamaNetworkDefine.h"
#import "MamaNetworkParams.h"
#import "MamaNetworkDomainAgent.h"
#import "NSString+MamaNetwork.h"
#import "NSMutableDictionary+MamaNetwork.h"

NSString *const mmwNetworkErrorKey = @"mmwNetworkErrorKey_";
NSString *const mmwNetworkDataKey = @"mmwNetworkDataKey_";
NSString *const mmwNetworkEnableDomainKey = @"mmwNetworkEnableDomainKey_";
NSString *const mmwNetworkReplaceIPDictKey = @"mmwNetworkReplaceIPDictKey_";
NSString *const mmwNetworkReplaceUrlKey = @"mmwNetworkReplaceUrlKey_";
NSString *const mmwNetworkOrignalUrlKey = @"mmwNetworkOrignalUrlKey_";
NSString *const mmwNetworkOrignalHostKey = @"mmwNetworkOrignalHostKey_";
NSString *const mmwNetworkResponseKey = @"mmwNetworkResponseKey_";
NSString *const mmwNetworkReturnDataBlockKey = @"mmwNetworkReturnDataBlockKey_";
NSString *const mmwNetworkRetryDataBlockKey = @"mmwNetworkRetryDataBlockKey_";

@interface MamaNetworkRequestAgent ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *dataTaskRecords;

@end

@implementation MamaNetworkRequestAgent{
    pthread_mutex_t _lock;
}
static MamaRequestReportBlock _reportBlock;

#pragma mark - life cycle

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

+ (instancetype)shared {
    static MamaNetworkRequestAgent *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MamaNetworkRequestAgent alloc] initSpecially];
    });
    return manager;
}

- (instancetype)initSpecially {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

+ (void)reportNetworkErrorInfo:(MamaRequestReportBlock)reportBlock {
    _reportBlock = reportBlock;
}

#pragma mark - public

- (void)cancelTaskWithIdentifier:(NSNumber *)aIdentifier {
    pthread_mutex_lock(&self->_lock);
    NSURLSessionTask *task = self.dataTaskRecords[aIdentifier];
    if (task) {
        [task cancel];
        [self.dataTaskRecords removeObjectForKey:aIdentifier];
    }
    pthread_mutex_unlock(&self->_lock);
}

- (void)cancelTaskWithIdentifiers:(NSArray <NSNumber *>*)identifiers {
    pthread_mutex_lock(&self->_lock);
    for (NSNumber *identifier in identifiers) {
        NSURLSessionTask *task = self.dataTaskRecords[identifier];
        if (task) {
            [task cancel];
            [self.dataTaskRecords removeObjectForKey:identifier];
        }
    }
    pthread_mutex_unlock(&self->_lock);
}

- (void)cancelTaskWithSessionTask:(NSURLSessionTask *)aTask {
    [self cancelTaskWithIdentifier:@(aTask.taskIdentifier)];
}

- (void)cancelTaskWithSessionTasks:(NSArray <NSURLSessionTask *>*)tasks {
    if (!tasks.count) {
        return;
    }
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:tasks.count];
    for (NSURLSessionTask *aTask in tasks) {
        [identifiers addObject:@(aTask.taskIdentifier)];
    }
    [self cancelTaskWithIdentifiers:identifiers];
}

- (void)cancelAllTask {
    pthread_mutex_lock(&self->_lock);
    for (NSURLSessionTask *task in self.dataTaskRecords.allValues) {
        [task cancel];
    }
    [self.dataTaskRecords removeAllObjects];
    pthread_mutex_unlock(&self->_lock);
}

- (NSURLSessionTask *)startNetworkingWithRequest:(MamaNetworkBaseRequest *)request
                              completion:(MamaRequestCompletionBlock)completionBlock
{
    // 构建网络请求数据步骤
    NSMutableDictionary *systemDict = [[self parameterForRequest:request] mutableCopy];
    NSURLSessionDataTask *task;
    
    switch (request.requestMethod) {
        case MamaRequestMethodPOST:
        {
            NSString *sign = [MamaNetworkParams appendParmas_PapiSign:[systemDict copy] sk:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:sign forKey:@"sign"];
            task = [self postNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        case MamaRequestMethodGET:
        {
            NSString *sign = [MamaNetworkParams appendParmas_PapiSign:[systemDict copy] sk:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:sign forKey:@"sign"];
            task = [self getNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        case MamaRequestMethodUPLOAD:
        {
            NSString *sign = [MamaNetworkParams appendParmas_PapiSign:[systemDict copy] sk:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:sign forKey:@"sign"];
            task = [self uploadNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        case MamaRequestMethodPOST_TOKEN:
        {
            NSString *token = [MamaNetworkParams appendParmas_PapiToken:[systemDict copy] sk:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:token forKey:@"token"];
            task = [self postNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        case MamaRequestMethodGET_TOKEN:
        {
            NSString *token = [MamaNetworkParams appendParmas_PapiToken:[systemDict copy] sk:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:token forKey:@"token"];
            task = [self getNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        case MamaRequestMethodUPLOAD_TOKEN:
        {
            NSString *token = [MamaNetworkParams appendParmas_PapiToken:[systemDict copy] sk:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:token forKey:@"token"];
            task = [self uploadNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        case MamaRequestMethodSearch:
        {
            NSString *sign = [MamaNetworkParams appendSearchUserToken:[systemDict copy] withSecureKey:request.requestSecureKey?:@""];
            [systemDict network_setStringObject:sign forKey:@"sign"];
            task = [self getNetworkingWithRequest:request paramsDict:systemDict completion:completionBlock];
        }
            break;
        default:
            break;
    }
    
    if (!task) {
        NSAssert(false, @"请求异常");
    }
    
    [task resume];
    NSNumber *taskIdentifier = @(task.taskIdentifier);
    
    pthread_mutex_lock(&self->_lock);
    self.dataTaskRecords[taskIdentifier] = task;
    pthread_mutex_unlock(&self->_lock);
    
    return task;
}

#pragma mark - 构造一个error

+ (NSError *)errorWithLocalizedDescriptionKey:(NSString *)aDescription {
    
    return [NSError errorWithDomain:@"network.mama.cn" code:-12580110 userInfo:@{NSLocalizedDescriptionKey:aDescription?:@""}];
}

/**
 *  是否开启了domian替换检查
 */
bool networkEnabelDomain(MamaNetworkBaseRequest *request) {
    if (![MamaNetworkDomainAgent domainSwitchEnable]) {
        return false;
    }
    if (!request.enableDomain) {
        return false;
    }
    return true;
}

#pragma mark - 构造 NSURLSessionDataTask

- (NSURLSessionDataTask *)uploadNetworkingWithRequest:(MamaNetworkBaseRequest *)request
                                           paramsDict:(NSDictionary *)paramsDict
                                           completion:(MamaRequestCompletionBlock)completionBlock
{
    
    NSString *urlString = [self urlStringForRequest:request];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. 构造是否成功
    if (![url isKindOfClass:NSURL.class]) {
        NSError *error = [self.class errorWithLocalizedDescriptionKey:@"url无效：构造对象失败"];
        if (completionBlock) {
            completionBlock(nil, error);
        }
        return nil;
    }
    
    NSString *newUrlString = [url absoluteString];
    NSString *hostDomain = [url host];
    NSDictionary *replacedIPDict = nil;
    
    // 3. 检查是否需要替换域名
    // replacedIPDict = @{@"remote_add": @"118.186.65.167", @"set_host": @1}
    if (networkEnabelDomain(request)) {
        // 需要替换
        if ([MamaNetworkDomainAgent shouldReplaceDomain:hostDomain]) {
            replacedIPDict = [MamaNetworkDomainAgent ipDictOfReplacedDomain:hostDomain];
            NSString *replaceHost = replacedIPDict[@"remote_add"];
            if (replaceHost.length) {
                if (hostDomain) {
                    NSRange hostDomainRange = [newUrlString rangeOfString:hostDomain];
                    newUrlString = [newUrlString stringByReplacingCharactersInRange:hostDomainRange withString:replaceHost];
                    // 3.1.替换完毕需要重新构造 url对象 是否有效
                    url = [NSURL URLWithString:newUrlString];
                    if (!url) {
                        NSError *error = [self.class errorWithLocalizedDescriptionKey:@"url无效：替换host后构造对象失败"];
                        if (completionBlock) {
                            completionBlock(nil, error);
                        }
                        return nil;
                    }
                }
            }
        }
    }
    
    // 5. 设置此时的url uuid cookies
    [MamaNetworkDomainAgent setupUUIDCookieOfURL:url];
    
    // 6. 构造请求
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    // 设置content-type
    NSString *boundary = @"AaS8HJ";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    NSString *dataKey = request.fileKey;
    NSString *dataName = request.fileName;
    
    NSString *fileExtension = [dataName pathExtension];
    NSString *mimeType = [NSString mamaNetwork_contentTypeOfFileExtension:fileExtension];
    
    //添加普通字段
    NSArray *keys = [paramsDict allKeys];
    NSMutableData *body = [NSMutableData data];
    for (NSInteger i = 0; i < [keys count]; i++) {
        NSString *key = [keys objectAtIndex:i];
        if (![key isEqualToString:dataKey]) {
            //添加分界符：--AaS8HJ
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            //声明一个字段：  content-disposition: form-data; name="字段名"
            [body appendData:[[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            //字段的值
            [body appendData:[[NSString stringWithFormat:@"%@\r\n", [paramsDict objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    // 加入一个图片data
    if (request.data && [request.data isKindOfClass:NSData.class]) {
        ////添加分界符：--AaS8HJ
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        //声明一个字段
        //content-disposition: form-data; name="pic"; filename="image.png"
        //Content-Type: image/png
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", dataKey, dataName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
        
        //添加图片的二进制内容
        [body appendData:request.data];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // post请求结尾的分界线，注意，这里是--AaS8HJ--，前后都有小横线
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:contentType forHTTPHeaderField:@"content-Type"];
    
    BOOL isNeedSetHost = [replacedIPDict[@"set_host"] boolValue];
    if (isNeedSetHost) { /// 替换为ip访问时需要设置header的Host
        [urlRequest setValue:hostDomain forHTTPHeaderField:@"Host"];
    }
    
    /// 往http header中设置参数
    NSDictionary *httpHeaderField = request.httpHeaderField;
    if ([httpHeaderField isKindOfClass:NSDictionary.class]) {
        [httpHeaderField enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [urlRequest setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    /// 如果检测到没有ua或被自定义的Header覆盖了，则通过request向业务层索要一个默认的ua
    httpHeaderField = [urlRequest.allHTTPHeaderFields copy];
    if (!httpHeaderField[@"User-Agent"] || ![httpHeaderField[@"User-Agent"] isKindOfClass:[NSString class]]) {
        [urlRequest setValue:[self userAgentForRequest:request] forHTTPHeaderField:@"User-Agent"];
    }
    
    __block NSURLSessionUploadTask *task = [[NSURLSession sharedSession] uploadTaskWithRequest:urlRequest
                                                                                            fromData:body
                                                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        pthread_mutex_lock(&self->_lock);
        [self.dataTaskRecords removeObjectForKey:@(task.taskIdentifier)];
        pthread_mutex_unlock(&self->_lock);
        
        if (error) {
            /// 假如返回错误，则判断是否已经是替换过ip请求的 还是 未替换ip请求的，分别处理
            MamaRequestRetryBlock retryDomainBlock = ^(void) {
                /// 自动重试
                [self uploadNetworkingWithRequest:request paramsDict:paramsDict completion:completionBlock];
            };
            NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
            [contextDict network_setObject:error forKey:mmwNetworkErrorKey];
            [contextDict network_setObject:replacedIPDict forKey:mmwNetworkReplaceIPDictKey];
            [contextDict network_setObject:newUrlString forKey:mmwNetworkReplaceUrlKey];
            [contextDict network_setObject:urlString forKey:mmwNetworkOrignalUrlKey];
            [contextDict network_setObject:hostDomain forKey:mmwNetworkOrignalHostKey];
            [contextDict network_setObject:completionBlock forKey:mmwNetworkReturnDataBlockKey];
            [contextDict network_setObject:retryDomainBlock forKey:mmwNetworkRetryDataBlockKey];
            [self dealErrorResultWithContext:contextDict];
            
        } else {
            
            /// 处理成功接口的数据流程
            NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
            [contextDict network_setObject:data forKey:mmwNetworkDataKey];
            [contextDict network_setObject:replacedIPDict forKey:mmwNetworkReplaceIPDictKey];
            [contextDict network_setObject:newUrlString forKey:mmwNetworkReplaceUrlKey];
            [contextDict network_setObject:hostDomain forKey:mmwNetworkOrignalHostKey];
            [contextDict network_setObject:response forKey:mmwNetworkResponseKey];
            [contextDict network_setObject:completionBlock forKey:mmwNetworkReturnDataBlockKey];
            [self dealSucceedResultWithContext:contextDict];
        }
    }];
    
    return task;
}

- (NSURLSessionDataTask *)postNetworkingWithRequest:(MamaNetworkBaseRequest *)request
                                         paramsDict:(NSDictionary *)paramsDict
                                          completion:(MamaRequestCompletionBlock)completionBlock
{
    
    NSString *urlString = [self urlStringForRequest:request];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. 构造是否成功
    if (![url isKindOfClass:NSURL.class]) {
        NSError *error = [self.class errorWithLocalizedDescriptionKey:@"url无效：构造对象失败"];
        if (completionBlock) {
            completionBlock(nil, error);
        }
        return nil;
    }
    
    NSString *newUrlString = [url absoluteString];
    NSString *hostDomain = [url host];
    NSDictionary *replacedIPDict = nil;
    
    // 3. 检查是否需要替换域名
    // replacedIPDict = @{@"remote_add": @"118.186.65.167", @"set_host": @1}
    if (networkEnabelDomain(request)) {
        if ([MamaNetworkDomainAgent shouldReplaceDomain:hostDomain]) { // 需要替换
            replacedIPDict = [MamaNetworkDomainAgent ipDictOfReplacedDomain:hostDomain];
            NSString *replaceHost = replacedIPDict[@"remote_add"];
            if (replaceHost.length) {
                if (hostDomain) {
                    NSRange hostDomainRange = [newUrlString rangeOfString:hostDomain];
                    newUrlString = [newUrlString stringByReplacingCharactersInRange:hostDomainRange withString:replaceHost];
                    // 3.1.替换完毕需要重新构造 url对象 是否有效
                    url = [NSURL URLWithString:newUrlString];
                    if (!url) {
                        NSError *error = [self.class errorWithLocalizedDescriptionKey:@"url无效：替换host后构造对象失败"];
                        if (completionBlock) {
                            completionBlock(nil, error);
                        }
                        return nil;
                    }
                }
            }
        }
    }
    
    // 5. 设置此时的url uuid cookies
    [MamaNetworkDomainAgent setupUUIDCookieOfURL:url];
    
    // 6. 构造请求
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setTimeoutInterval:request.timeInterval];
    
    NSData *postData;
    if (request.body && [request.body isKindOfClass:NSData.class]) {
        postData = request.body;
    } else {
        NSString *parametersString = [MamaNetworkParams completeUrlForGet:paramsDict withURLPrefix:nil withCompare:false];
        postData = [parametersString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    }
    [urlRequest setHTTPBody:postData];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [urlRequest setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    
    BOOL isNeedSetHost = [replacedIPDict[@"set_host"] boolValue];
    if (isNeedSetHost) { /// 替换为ip访问时需要设置header的Host
        [urlRequest setValue:hostDomain forHTTPHeaderField:@"Host"];
    }
    
    /// 往http header中设置参数
    NSDictionary *httpHeaderField = request.httpHeaderField;
    if ([httpHeaderField isKindOfClass:NSDictionary.class]) {
        [httpHeaderField enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [urlRequest setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    /// 如果检测到没有ua或被自定义的Header覆盖了，则通过request向业务层索要一个默认的ua
    httpHeaderField = [urlRequest.allHTTPHeaderFields copy];
    if (!httpHeaderField[@"User-Agent"] || ![httpHeaderField[@"User-Agent"] isKindOfClass:[NSString class]]) {
        [urlRequest setValue:[self userAgentForRequest:request] forHTTPHeaderField:@"User-Agent"];
    }

    /// 构造请求
    __block NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest
                                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        pthread_mutex_lock(&self->_lock);
        [self.dataTaskRecords removeObjectForKey:@(task.taskIdentifier)];
        pthread_mutex_unlock(&self->_lock);
        
        if (error) {
            /// 假如返回错误，则判断是否已经是替换过ip请求的 还是 未替换ip请求的，分别处理
            MamaRequestRetryBlock retryDomainBlock = ^(void) {
                /// 自动重试
                [self postNetworkingWithRequest:request paramsDict:paramsDict completion:completionBlock];
            };
            NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
            [contextDict network_setObject:error forKey:mmwNetworkErrorKey];
            [contextDict network_setObject:replacedIPDict forKey:mmwNetworkReplaceIPDictKey];
            [contextDict network_setObject:newUrlString forKey:mmwNetworkReplaceUrlKey];
            [contextDict network_setObject:urlString forKey:mmwNetworkOrignalUrlKey];
            [contextDict network_setObject:hostDomain forKey:mmwNetworkOrignalHostKey];
            [contextDict network_setObject:completionBlock forKey:mmwNetworkReturnDataBlockKey];
            [contextDict network_setObject:retryDomainBlock forKey:mmwNetworkRetryDataBlockKey];
            [self dealErrorResultWithContext:contextDict];
            
        } else {
            
            /// 处理成功接口的数据流程
            NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
            [contextDict network_setObject:data forKey:mmwNetworkDataKey];
            [contextDict network_setObject:replacedIPDict forKey:mmwNetworkReplaceIPDictKey];
            [contextDict network_setObject:newUrlString forKey:mmwNetworkReplaceUrlKey];
            [contextDict network_setObject:hostDomain forKey:mmwNetworkOrignalHostKey];
            [contextDict network_setObject:response forKey:mmwNetworkResponseKey];
            [contextDict network_setObject:completionBlock forKey:mmwNetworkReturnDataBlockKey];
            [self dealSucceedResultWithContext:contextDict];
        }
    }];
    
    return task;
}

- (NSURLSessionDataTask *)getNetworkingWithRequest:(MamaNetworkBaseRequest *)request
                                         paramsDict:(NSDictionary *)paramsDict
                                         completion:(MamaRequestCompletionBlock)completionBlock {
    
    NSString *urlString = [self urlStringForRequest:request];
    urlString = [MamaNetworkParams completeUrlForGet:[paramsDict copy] withURLPrefix:urlString withCompare:NO];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. 构造是否成功
    if (![url isKindOfClass:NSURL.class]) {
        NSError *error = [self.class errorWithLocalizedDescriptionKey:@"url无效：构造对象失败"];
        if (completionBlock) {
            completionBlock(nil, error);
        }
        return nil;
    }
    
    // 2.1.拼接参数
    NSString *newUrlString = [url absoluteString];
    NSString *hostDomain = [url host];
    NSDictionary *replacedIPDict = nil;
    
    // 3.检查是否需要替换域名
    // replacedIPDict = @{@"remote_add": @"118.186.65.167", @"set_host": @1}
    if (networkEnabelDomain(request)) {
        if ([MamaNetworkDomainAgent shouldReplaceDomain:hostDomain]) { // 需要替换
            replacedIPDict = [MamaNetworkDomainAgent ipDictOfReplacedDomain:hostDomain];
            NSString *replaceHost = replacedIPDict[@"remote_add"];
            if (replaceHost.length) {
                if (hostDomain) {
                    NSRange hostDomainRange = [newUrlString rangeOfString:hostDomain];
                    newUrlString = [newUrlString stringByReplacingCharactersInRange:hostDomainRange withString:replaceHost];
                    // 3.1.替换完毕需要重新构造 url对象 是否有效
                    url = [NSURL URLWithString:newUrlString];
                    if (!url) {
                        NSError *error = [self.class errorWithLocalizedDescriptionKey:@"url无效：替换host后构造对象失败"];
                        if (completionBlock) {
                            completionBlock(nil, error);
                        }
                        return nil;
                    }
                }
            }
        }
    }
    
    // 5. 设置此时的url uuid cookies
    [MamaNetworkDomainAgent setupUUIDCookieOfURL:url];
    
    // 6. 构造请求
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    
    [urlRequest setURL:url];
    urlRequest.timeoutInterval = request.timeInterval;
    
    /// 是否需要设置header的Host，替换为ip访问时需要设置header的Host
    BOOL isNeedSetHost = [replacedIPDict[@"set_host"] boolValue];
    if (isNeedSetHost) {
        [urlRequest setValue:hostDomain forHTTPHeaderField:@"Host"];
    }
    
    /// 往http header中设置参数
    NSDictionary *httpHeaderField = request.httpHeaderField;
    if ([httpHeaderField isKindOfClass:NSDictionary.class]) {
        [httpHeaderField enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [urlRequest setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    /// 如果检测到没有ua，则通过request向业务层索要一个
    httpHeaderField = [urlRequest.allHTTPHeaderFields copy];
    if (!httpHeaderField[@"User-Agent"] || ![httpHeaderField[@"User-Agent"] isKindOfClass:[NSString class]]) {
        [urlRequest setValue:[self userAgentForRequest:request] forHTTPHeaderField:@"User-Agent"];
    }
    
    __block NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        pthread_mutex_lock(&self->_lock);
        [self.dataTaskRecords removeObjectForKey:@(task.taskIdentifier)];
        pthread_mutex_unlock(&self->_lock);
        
        if (error) {
            /// 假如返回错误，则判断是否已经是替换过ip请求的 还是 未替换ip请求的，分别处理
            MamaRequestRetryBlock retryDomainBlock = ^(void) {
                /// 自动重试
                [self getNetworkingWithRequest:request paramsDict:paramsDict completion:completionBlock];
            };
            NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
            [contextDict network_setObject:error forKey:mmwNetworkErrorKey];
            [contextDict network_setObject:replacedIPDict forKey:mmwNetworkReplaceIPDictKey];
            [contextDict network_setObject:newUrlString forKey:mmwNetworkReplaceUrlKey];
            [contextDict network_setObject:urlString forKey:mmwNetworkOrignalUrlKey];
            [contextDict network_setObject:hostDomain forKey:mmwNetworkOrignalHostKey];
            [contextDict network_setObject:completionBlock forKey:mmwNetworkReturnDataBlockKey];
            [contextDict network_setObject:retryDomainBlock forKey:mmwNetworkRetryDataBlockKey];
            [self dealErrorResultWithContext:contextDict];
            
        } else {
            
            NSMutableDictionary *contextDict = [NSMutableDictionary dictionary];
            [contextDict network_setObject:data forKey:mmwNetworkDataKey];
            [contextDict network_setObject:replacedIPDict forKey:mmwNetworkReplaceIPDictKey];
            [contextDict network_setObject:newUrlString forKey:mmwNetworkReplaceUrlKey];
            [contextDict network_setObject:hostDomain forKey:mmwNetworkOrignalHostKey];
            [contextDict network_setObject:response forKey:mmwNetworkResponseKey];
            [contextDict network_setObject:completionBlock forKey:mmwNetworkReturnDataBlockKey];
            [self dealSucceedResultWithContext:contextDict];
        }
    }];
    
    return task;
}

#pragma mark - 接口请求成功的数据解析流程

- (void)dealSucceedResultWithContext:(NSDictionary *)context
{
    NSData *data                                = [context objectForKey:mmwNetworkDataKey];
    NSDictionary *replacedIPDict                = [context objectForKey:mmwNetworkReplaceIPDictKey];
    NSString *replacedURLPath                   = [context objectForKey:mmwNetworkReplaceUrlKey];
    NSString *originalHostDomain                = [context objectForKey:mmwNetworkOrignalHostKey];
    NSURLResponse *response                     = [context objectForKey:mmwNetworkResponseKey];
    MamaRequestCompletionBlock returnDataBlock  = [context objectForKey:mmwNetworkReturnDataBlockKey];
    
    // 记录4xx和5xx错误
    NSHTTPURLResponse *urlResponse = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        urlResponse = (NSHTTPURLResponse *)response;
        NSString *statusCode = [NSString stringWithFormat:@"%ld", urlResponse.statusCode];
        if ([statusCode hasPrefix:@"4"] || [statusCode hasPrefix:@"5"]) {
            NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
            [messageDict network_setObject:replacedURLPath forKey:@"url"];
            [messageDict network_setObject:statusCode forKey:@"repocode"];
            if (_reportBlock) {
                _reportBlock([messageDict copy], 14);
            }
        }
    }
    
    NSDictionary *json;
    NSError *error;
    if (data) {
        json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    }
    if (!json || ![json isKindOfClass:NSDictionary.class]) {
        if (returnDataBlock) {
            error = error ?: [self.class errorWithLocalizedDescriptionKey:@"接口数据解析失败"];
            returnDataBlock(nil, error);
        }
    } else {
        if (returnDataBlock) {
            returnDataBlock(json, nil);
        }
    }
    
    /// 检查是否需要上报
    if (originalHostDomain && ![replacedURLPath rangeOfString:originalHostDomain].length) {
        // 替换域名有效
        NSString *protocol = [NSURL URLWithString:replacedURLPath].scheme;
        NSString *remoteAddr = replacedIPDict[@"remote_add"];
        NSDictionary *messageDict = [self.class dictionaryOfRecordWithOriginalHostDomain:originalHostDomain replaceHostDomain:remoteAddr protocol:protocol urlPath:replacedURLPath];
        if (_reportBlock) {
            _reportBlock(messageDict, 5);
        }
    }
}

#pragma mark - 接口第一次请求失败的数据处理流程

- (void)dealErrorResultWithContext:(NSDictionary *)context {
    
    NSError *error                              = [context objectForKey:mmwNetworkErrorKey];
    BOOL enableDomain                           = [[context objectForKey:mmwNetworkEnableDomainKey] boolValue];
    NSDictionary *replacedIPDict                = [context objectForKey:mmwNetworkReplaceIPDictKey];
    NSString *replacedURLPath                   = [context objectForKey:mmwNetworkReplaceUrlKey];
    NSString *originalURLPath                   = [context objectForKey:mmwNetworkOrignalUrlKey];
    NSString *originalHostDomain                = [context objectForKey:mmwNetworkOrignalHostKey];
    MamaRequestCompletionBlock returnDataBlock  = [context objectForKey:mmwNetworkReturnDataBlockKey];
    MamaRequestRetryBlock retryDomainBlock      = [context objectForKey:mmwNetworkRetryDataBlockKey];
    
    if (![MamaNetworkDomainAgent domainSwitchEnable] || // 不开启domain检查就可以终止流程了
        !enableDomain ||    // 根据当前的request判断是否允许发起
        !originalHostDomain ||  // 无效url
        error.code == NSURLErrorCancelled   // 请求取消
        ) {
        if (returnDataBlock) {
            returnDataBlock(nil, error);
        }
        return;
    }
    
    NSString *protocol = [NSURL URLWithString:originalURLPath].scheme;

    // 原始host，未替换过
    if ([replacedURLPath rangeOfString:originalHostDomain].length) {
        
        // ip替换列表存在且未过期
        if ([MamaNetworkDomainAgent isIPListExistsAndNotExpiredOfDomain:originalHostDomain]) {
            
            [self dealDomainReqWithOrError:error repoertType:2 shouldReplaceMark:YES originalHostDomain:originalHostDomain protocol:protocol urlPath:replacedURLPath returnDataBlock:returnDataBlock];
            
        }else {
            
            // 没有ip替换列表，去请求
            [MamaNetworkDomainAgent requestNetworkIPsAtDomain:originalHostDomain successBlock:^{ // 请求成功
                
                [self dealDomainReqWithOrError:error repoertType:2 shouldReplaceMark:YES originalHostDomain:originalHostDomain protocol:protocol urlPath:replacedURLPath returnDataBlock:returnDataBlock];
                
            } failureBlock:^{
                
                // 获取域名替换列表失败，取本地保存的最近可用的替换域名，如果存在拿来使用，不存在则提示网络不可访问
                NSArray *latestIPList = [MamaNetworkDomainAgent ipListOfDomain:originalHostDomain];
                
                // 存在旧的缓存数据
                if (latestIPList.count) {
                    
                    [self dealDomainReqWithOrError:error repoertType:2 shouldReplaceMark:YES originalHostDomain:originalHostDomain protocol:protocol urlPath:replacedURLPath returnDataBlock:returnDataBlock];
                    
                } else {
                    
                    [self dealDomainReqWithOrError:error repoertType:1 shouldReplaceMark:NO originalHostDomain:originalHostDomain protocol:protocol urlPath:replacedURLPath returnDataBlock:returnDataBlock];
                }
            }];
        }
    }
    
    // 当前替换ip让无效（需移除），找下一个ip替换掉然后自动请求，如果替换列表只剩下一条数据时就不delete了后面都用这最后一条数据替换直到5分钟后清除
    else {
        
        NSString *remoteAddr = replacedIPDict[@"remote_add"];
        NSDictionary *messageDict = [self.class dictionaryOfRecordWithOriginalHostDomain:originalHostDomain replaceHostDomain:remoteAddr protocol:protocol urlPath:replacedURLPath];
        if (_reportBlock) {
            _reportBlock(messageDict, 4);
        }
        
        // 证书问题，再次上报记录
        if (error.code == NSURLErrorServerCertificateUntrusted ||
            error.code == NSURLErrorServerCertificateHasUnknownRoot ||
            error.code == NSURLErrorServerCertificateNotYetValid) {
            if (_reportBlock) {
                _reportBlock(messageDict, 12);
            }
        }
        
        NSArray *ipList = [MamaNetworkDomainAgent ipListOfDomain:originalHostDomain];
        if (ipList.count >= 2) {
            [MamaNetworkDomainAgent deleteInvalidIPDict:replacedIPDict fromIPListOfDomain:originalHostDomain];
            // domain数量充足情况下自动重试
            if (retryDomainBlock) {
                retryDomainBlock();
            }
        } else {
            if (_reportBlock) {
                _reportBlock(messageDict, 3);
            }
            // domain数量重试到数量为1的情况下仍失败就会直接返回结果
            if (returnDataBlock) {
                returnDataBlock(nil, error);
            }
        }
        
    }
}

#pragma mark - 域名替换结果的处理流程

- (void)dealDomainReqWithOrError:(NSError *)error
                     repoertType:(int)repoertType
               shouldReplaceMark:(BOOL)shouldReplaceMark
              originalHostDomain:(NSString *)originalHostDomain
                        protocol:(NSString *)protocol
                         urlPath:(NSString *)urlPath
                 returnDataBlock:(MamaRequestCompletionBlock)returnDataBlock
{
    // 1. 标记域名需要替换
    [MamaNetworkDomainAgent saveDomainShouldReplaceMark:shouldReplaceMark ofDomain:originalHostDomain];
    
    // 2. 基础错误信息，记录日志
    NSDictionary *messageDict = [self.class dictionaryOfRecordWithOriginalHostDomain:originalHostDomain replaceHostDomain:nil protocol:protocol urlPath:urlPath];
    if (_reportBlock) {
        _reportBlock(messageDict, repoertType);
    }
    
    // 3. 详细判断证书问题，记录日志
    if (error.code == NSURLErrorServerCertificateUntrusted ||
        error.code == NSURLErrorServerCertificateHasUnknownRoot ||
        error.code == NSURLErrorServerCertificateNotYetValid) {
        if (_reportBlock) {
            _reportBlock(messageDict, 12);
        }
    }
    
    // 4. 回调请求结果
    if (returnDataBlock) {
        returnDataBlock(nil, error);
    }
}

#pragma mark - 数据解析过程中的一些上报日志

+ (NSDictionary *)dictionaryOfRecordWithOriginalHostDomain:(NSString *)originalHostDomain
                                         replaceHostDomain:(NSString *)replaceHostDomain
                                                  protocol:(NSString *)protocol
                                                   urlPath:(NSString *)urlPath
{
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    [messageDict network_setObject:replaceHostDomain forKey:@"remoteaddr"];
    [messageDict network_setObject:originalHostDomain forKey:@"host"];
    [messageDict network_setObject:protocol forKey:@"protocol"];
    [messageDict network_setObject:urlPath forKey:@"url"];
    return [messageDict copy];
}

#pragma mark - 参数信息

- (NSString *)urlStringForRequest:(MamaNetworkBaseRequest *)request {
    NSURL *url;
    if (request.mockURI.length) {
        @try {
            url = [NSURL URLWithString:request.mockURI];
        } @catch (NSException *exception) {
        } @finally {
        }
        return [url absoluteString];
    }
    @try {
        url = [NSURL URLWithString:request.baseURI];
        if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
            url = [url URLByAppendingPathComponent:@""];
        }
        url = [NSURL URLWithString:request.requestURI relativeToURL:url];
    } @catch (NSException *exception) {
    } @finally {
    }
    return [url absoluteString];
}

- (NSDictionary *)parameterForRequest:(MamaNetworkBaseRequest *)request {
    NSDictionary *parameter = request.requestParameter;
    if ([request respondsToSelector:@selector(mamanetwork_preprocessParameter:)]) {
        parameter = [request mamanetwork_preprocessParameter:parameter];
    }
    if (request.FixRequestParameter) {
        parameter = request.FixRequestParameter(parameter.mutableCopy);
    }
    return parameter;
}

- (NSString *)userAgentForRequest:(MamaNetworkBaseRequest *)request {
    NSString *userAgent = @"";
    if ([request respondsToSelector:@selector(mamanetwork_preprocessUserAgentWhenNotFound)]) {
        userAgent = [request mamanetwork_preprocessUserAgentWhenNotFound];
    }
    return userAgent;
}

#pragma mark - getter

- (NSMutableDictionary<NSNumber *,NSURLSessionTask *> *)dataTaskRecords {
    if (!_dataTaskRecords) {
        _dataTaskRecords = [NSMutableDictionary dictionary];
    }
    return _dataTaskRecords;
}

@end
