//
//  NSMutableDictionary+MamaNetwork.m
//  MamaNetwork
//
//  Created by tanxl on 2022/5/18.
//  Copyright © 2022 mamawangtanxl. All rights reserved.
//

#import "NSMutableDictionary+MamaNetwork.h"

@implementation NSMutableDictionary (MamaNetwork)

- (void)network_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (anObject && aKey) {
        [self setObject:anObject forKey:aKey];
    }
}

- (void)network_setStringObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if (!anObject || !aKey) {
        return;
    }
    if ([anObject isKindOfClass:NSString.class]) {
        [self setObject:anObject forKey:aKey];
    }
    else if ([anObject isKindOfClass:NSNumber.class]) {
        [self setObject:[((NSNumber *)anObject) stringValue] forKey:aKey];
    }
}

@end
