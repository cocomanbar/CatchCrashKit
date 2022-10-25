//
//  NSString+MamaNetwork.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/17.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "NSString+MamaNetwork.h"
#import <CommonCrypto/CommonHMAC.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSString (MamaNetwork)

- (NSString *)mamaNetwork_md5;
{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSString *)mamaNetwork_urlEncode{
    NSString *result;
    // 暂时不要用这个，因为空格有问题，导致url为空
//    if (@available(iOS 9, *)) {
//        NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@":/?&=;+!@#$()',*"] invertedSet];
//        result = [self stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
//    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?&=;+!@#$()',*"), kCFStringEncodingUTF8));
#pragma clang diagnostic pop
//    }
    return result;
}

+ (NSString *)mamaNetwork_appVersion{
    NSString *version = [NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    return version;
}

- (BOOL)mamaNetwork_isContainsEnglishCharacter {
    if (!self.length) {
        return NO;
    }
    NSString *pattern = @"[A-Za-z]";
    NSRegularExpression *regularExpression = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *allResults = [regularExpression matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    return allResults.count;
}

// 根据文件扩展名生成对应的contentType
+ (NSString *)mamaNetwork_contentTypeOfFileExtension:(NSString *)fileExtension {
    if (!fileExtension.length) {
        return @"application/octet-stream";
    }
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

@end
