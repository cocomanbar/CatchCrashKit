//
//  MamaNetworkCache.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkCache.h"

@interface MamaNetworkCachePackage : NSObject <NSCoding>
@property (nonatomic, strong) id<NSCoding> object;
@property (nonatomic, strong) NSDate *updateDate;
@end
@implementation MamaNetworkCachePackage
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    self.object = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(object))];
    self.updateDate = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(updateDate))];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.object forKey:NSStringFromSelector(@selector(object))];
    [aCoder encodeObject:self.updateDate forKey:NSStringFromSelector(@selector(updateDate))];
}
@end

static NSString * const MamaNetworkCacheName = @"MamaNetworkCacheFiles";
static YYDiskCache *_diskCache = nil;
static YYMemoryCache *_memoryCache = nil;

@implementation MamaNetworkCache

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.writeMode = MamaNetworkCacheWriteModeNone;
        self.readMode = MamaNetworkCacheReadModeNone;
        self.cacheTimeInterval = 7 * 24 * 60 * 60;
    }
    return self;
}

#pragma mark - public

+ (NSInteger)getDiskCacheSize {
    return [MamaNetworkCache.diskCache totalCost] / 1024.0 / 1024.0;
}

+ (void)removeDiskCache {
    [MamaNetworkCache.diskCache removeAllObjects];
}

+ (void)removeMemeryCache {
    [MamaNetworkCache.memoryCache removeAllObjects];
}

#pragma mark - internal

- (void)setObject:(id<NSCoding>)object forKey:(id)key {
    if (!object || !key) {
        return;
    }
    MamaNetworkCachePackage *package = [MamaNetworkCachePackage new];
    package.object = object;
    package.updateDate = [NSDate date];
    
    if (self.writeMode & MamaNetworkCacheWriteModeMemory) {
        [MamaNetworkCache.memoryCache setObject:package forKey:key];
    }
    if (self.writeMode & MamaNetworkCacheWriteModeDisk) {
        [MamaNetworkCache.diskCache setObject:package forKey:key withBlock:^{}]; //子线程执行，空闭包仅为了去除警告
    }
}

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id <NSCoding>object))block {
    if (!block) return;
    
    void(^callBack)(id<NSCoding>) = ^(id<NSCoding> obj) {
        MamaNetworkCachePackage *package = (MamaNetworkCachePackage *)obj;
        if (!package || ![package isKindOfClass:MamaNetworkCachePackage.class]) {
            block(key, nil);
            return;
        }
        if (-[package.updateDate timeIntervalSinceNow] > self.cacheTimeInterval) {
            block(key, nil);
        } else {
            block(key, package.object);
        }
    };
    
    id<NSCoding> object = [MamaNetworkCache.memoryCache objectForKey:key];
    if (object) {
        callBack(object);
    } else {
        [MamaNetworkCache.diskCache objectForKey:key withBlock:^(NSString *key, id<NSCoding> object) {
            if (object) {
                [MamaNetworkCache.memoryCache setObject:object forKey:key];
            }
            callBack(object);
        }];
    }
}

- (void)removeObjectForKey:(id)key{
    if (!key) {
        return;
    }
    if ([MamaNetworkCache.memoryCache containsObjectForKey:key]) {
        [MamaNetworkCache.memoryCache removeObjectForKey:key];
    }
    if ([MamaNetworkCache.diskCache containsObjectForKey:key]) {
        [MamaNetworkCache.diskCache removeObjectForKey:key];
    }
}

#pragma mark - getter and setter

+ (YYDiskCache *)diskCache {
    if (!_diskCache) {
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:MamaNetworkCacheName];
        _diskCache = [[YYDiskCache alloc] initWithPath:path];
    }
    return _diskCache;
}

+ (void)setDiskCache:(YYDiskCache *)diskCache {
    _diskCache = diskCache;
}

+ (YYMemoryCache *)memoryCache {
    if (!_memoryCache) {
        _memoryCache = [YYMemoryCache new];
        _memoryCache.name = MamaNetworkCacheName;
    }
    return _memoryCache;
}

+ (void)setMemoryCache:(YYMemoryCache *)memoryCache {
    _memoryCache = memoryCache;
}

@end
