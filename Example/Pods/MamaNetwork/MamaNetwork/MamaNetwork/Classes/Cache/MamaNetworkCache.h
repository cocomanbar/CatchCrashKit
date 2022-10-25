//
//  MamaNetworkCache.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MamaNetworkDefine.h"
#import "YYCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface MamaNetworkCache : NSObject

/** 缓存存储模式 (默认不缓存) */
@property (nonatomic, assign) MamaNetworkCacheWriteMode writeMode;

/** 缓存读取模式 (默认不读取) */
@property (nonatomic, assign) MamaNetworkCacheReadMode readMode;

/** 缓存有效时长 (单位：秒，默认7天：7 * 24 * 60 * 60) */
@property (nonatomic, assign) NSTimeInterval cacheTimeInterval;

/** 根据请求成功数据判断是否需要缓存 (保证仅在数据有效时返回 YES) */
@property (nonatomic, copy, nullable) BOOL(^shouldCacheBlock)(NSDictionary *response);

/** 根据默认的缓存 key 自定义缓存 key */
@property (nonatomic, copy, nullable) NSString *(^customCacheKeyBlock)(NSString *defaultCacheKey);

/**
 获取磁盘缓存大小
 
 @return 缓存大小(单位 M)
 */
+ (NSInteger)getDiskCacheSize;

/**
 清除磁盘缓存
 */
+ (void)removeDiskCache;

/**
 清除内存缓存
 */
+ (void)removeMemeryCache;

/** 磁盘缓存对象 */
@property (nonatomic, class, readonly, nullable) YYDiskCache *diskCache;

/** 内存缓存对象 */
@property (nonatomic, class, readonly, nullable) YYMemoryCache *memoryCache;

/**
 存数据
 
 @param object 数据对象[NSDictionary class]，因为涉及到解析对象的问题，存原始字典数据方便
 @param key 标识
 */
- (void)setObject:(id<NSCoding> _Nullable)object forKey:(id _Nullable)key;

/**
 取数据
 
 @param key 标识
 @param block 回调
 */
- (void)objectForKey:(NSString * _Nullable)key withBlock:(void(^)(NSString *key, id <NSCoding>object))block;

/**
 删数据

 @param key key description
 */
- (void)removeObjectForKey:(id _Nullable)key;

@end

NS_ASSUME_NONNULL_END

