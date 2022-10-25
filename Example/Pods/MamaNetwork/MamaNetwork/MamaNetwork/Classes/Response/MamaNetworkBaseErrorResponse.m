//
//  MamaNetworkBaseErrorResponse.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/23.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkBaseErrorResponse.h"

@implementation MamaNetworkBaseErrorResponse

+ (instancetype)setDefaultModel:(NSError *)error{
    MamaNetworkBaseErrorResponse *model = [[MamaNetworkBaseErrorResponse alloc] init];
    NSInteger code = error.code;
    NSString *msg = @"网络异常，无法获取数据";
    switch (error.code) {
        case NSURLErrorTimedOut:
            msg = @"网络异常，无法获取数据";
            break;
        case NSURLErrorCancelled:
            msg = @"网络异常，无法获取数据";
            break;
    }
    model.code = code;
    model.msg = msg;
    model.error = error;
    return model;
}

@end
