//
//  NSString+MamaNetwork.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/17.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MamaNetwork)

// MD5
- (NSString * _Nullable)mamaNetwork_md5;

// app版本
+ (NSString * _Nullable)mamaNetwork_appVersion;

// 对 URL 进行 Encode
- (NSString * _Nullable)mamaNetwork_urlEncode;

// 是否包含英文字符
- (BOOL)mamaNetwork_isContainsEnglishCharacter;

// 根据文件扩展名生成对应的contentType
+ (NSString * _Nullable)mamaNetwork_contentTypeOfFileExtension:(NSString * _Nullable)fileExtension;

@end

NS_ASSUME_NONNULL_END
