//
//  MamaNetworkBaseTokenResponse.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/23.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkBaseTokenResponse.h"

@implementation MamaNetworkBaseTokenErrorResponse

+ (NSDictionary *)mj_replacedKeyFromPropertyName{
    return @{
             @"errNo" : @"errno"
             };
}

@end

@implementation MamaNetworkBaseTokenResponse

@end



