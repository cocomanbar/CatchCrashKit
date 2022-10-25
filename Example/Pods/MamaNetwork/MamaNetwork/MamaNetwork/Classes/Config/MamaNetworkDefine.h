//
//  MamaNetworkDefine.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#ifndef MamaNetworkDefine_h
#define MamaNetworkDefine_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 请求类型
typedef NS_ENUM(NSInteger, MamaRequestMethod) {
    /* sign */
    MamaRequestMethodPOST,
    MamaRequestMethodGET,
    MamaRequestMethodUPLOAD,
    MamaRequestMethodSearch,    // 兼容孕育里面的system的appendSearchUserToken方法
    /* token */
    MamaRequestMethodPOST_TOKEN,
    MamaRequestMethodGET_TOKEN,
    MamaRequestMethodUPLOAD_TOKEN,
};

/// 针对接口开放的API
typedef NS_ENUM(NSInteger, MamaNetworkCacheMode){
    MamaNetworkCacheModeNone,   //屏蔽缓存(默认)
    MamaNetworkCacheModeDone,   //启动缓存
};

/// 缓存存储模式，针对[MamaNetworkCache]
typedef NS_OPTIONS(NSUInteger, MamaNetworkCacheWriteMode) {
    MamaNetworkCacheWriteModeNone = 0,            //无缓存
    MamaNetworkCacheWriteModeMemory = 1 << 0,     //内存缓存
    MamaNetworkCacheWriteModeDisk = 1 << 1,       //磁盘缓存
    MamaNetworkCacheWriteModeMemoryAndDisk = MamaNetworkCacheWriteModeMemory | MamaNetworkCacheWriteModeDisk,
};

/// 缓存读取模式，针对[MamaNetworkCache]
typedef NS_ENUM(NSInteger, MamaNetworkCacheReadMode) {
    MamaNetworkCacheReadModeNone,            //不读取缓存
    MamaNetworkCacheReadModeAlsoNetwork,     //缓存命中后仍然发起网络请求
    MamaNetworkCacheReadModeCancelNetwork,   //缓存命中后不发起网络请求
};

/// 缓存回调处理策略：仅在[MamaNetworkCacheReadModeAlsoNetwork]下有效
typedef NS_ENUM(NSInteger, MamaNetworkCacheBackMode){
    MamaNetworkCacheBackModeRequestStart,   //请求前匹配到缓存就立刻返回
    MamaNetworkCacheBackModeRequestEnd,     //请求结束后，如果请求数据成功既不返回缓存，如果请求数据失败且匹配到缓存就返回
};

/// 网络请求释放策略
typedef NS_ENUM(NSInteger, MamaNetworkReleaseStrategy) {
    MamaNetworkReleaseStrategyWhenRequestDealloc, //网络请求将随着 MamaBaseRequest 实例的释放而取消
    MamaNetworkReleaseStrategyHoldRequest,        //网络任务会持有 MamaBaseRequest 实例，网络任务完成 MamaBaseRequest 实例才会释放
    MamaNetworkReleaseStrategyNotCareRequest,      //网络请求和 MamaBaseRequest 实例无关联
};

/// 重复网络请求处理策略
typedef NS_ENUM(NSInteger, MamaNetworkRepeatStrategy) {
    MamaNetworkRepeatStrategyAllAllowed,     //允许重复网络请求
    MamaNetworkRepeatStrategyCancelOldest,   //取消最旧的网络请求
    MamaNetworkRepeatStrategyCancelNewest,    //取消最新的网络请求
};

@class MamaNetworkBaseRequest;
@class MamaNetworkBaseResponse;
@class MamaNetworkBaseTokenResponse;
@class MamaNetworkBaseErrorResponse;

/// 进度闭包
typedef void(^MamaRequestProgressBlock)(NSProgress * _Nullable progress);

/// 缓存命中闭包 <MamaNetworkBaseResponse>
typedef void(^MamaRequestCacheBlock)(MamaNetworkBaseResponse * _Nullable response);

/// 请求成功闭包 <MamaNetworkBaseResponse/MamaNetworkBaseTokenResponse>
typedef void(^MamaRequestSuccessBlock)(id _Nullable response);

/// 请求失败闭包 <MamaNetworkBaseResponse/MamaNetworkBaseTokenResponse>
typedef void(^MamaRequestFailureBlock)(id _Nullable response);

/// 网络失败闭包 <MamaNetworkBaseErrorResponse>
typedef void(^MamaRequestNetErrorBlock)(MamaNetworkBaseErrorResponse * _Nullable error);

NS_ASSUME_NONNULL_END

#endif /* MamaNetworkDefine_h */


