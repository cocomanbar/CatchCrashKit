//
//  NSMutableDictionary+MamaNetwork.h
//  MamaNetwork
//
//  Created by tanxl on 2022/5/18.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (MamaNetwork)

- (void)network_setObject:(id _Nullable)anObject forKey:(id<NSCopying> _Nullable)aKey;

- (void)network_setStringObject:(id _Nullable)anObject forKey:(id<NSCopying> _Nullable)aKey;

@end

NS_ASSUME_NONNULL_END
