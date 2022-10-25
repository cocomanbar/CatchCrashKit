//
//  MamaNetworkRequestAgent.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MamaNetworkBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MamaRequestRetryBlock)(void);
typedef void(^MamaRequestReportBlock)(NSDictionary * _Nullable message, int type);
typedef void(^MamaRequestCompletionBlock)(id _Nullable responseObject, NSError * _Nullable error);

@interface MamaNetworkRequestAgent : NSObject

+ (instancetype)shared;
- (instancetype)init OBJC_UNAVAILABLE("use '+sharedManager' instead");
+ (instancetype)new OBJC_UNAVAILABLE("use '+sharedManager' instead");

/// 记录错误
/// 1:用户网络不可访问 2:用户网络错误，请重试 3:用户网络错误，并且没有域名可以替换 4:替换了的域名也出现网络错误。 5:替换了的域名访问正常。
/// 6:修复包安装成功。7:修复包安装失败。8: 用户行为。9: 自定义事件。10: 系统闪退或代码异常。11：用户信息出错
+ (void)reportNetworkErrorInfo:(MamaRequestReportBlock)reportBlock;

/// 开启请求
- (nullable NSURLSessionTask *)startNetworkingWithRequest:(MamaNetworkBaseRequest *)request completion:(MamaRequestCompletionBlock)completionBlock;

/// 取消请求
- (void)cancelTaskWithIdentifier:(NSNumber * _Nullable )aIdentifier;
- (void)cancelTaskWithIdentifiers:(NSArray <NSNumber *>* _Nullable)identifiers;

- (void)cancelTaskWithSessionTask:(NSURLSessionTask * _Nullable)aTask;
- (void)cancelTaskWithSessionTasks:(NSArray <NSURLSessionTask *>* _Nullable)tasks;

- (void)cancelAllTask;

@end

NS_ASSUME_NONNULL_END
