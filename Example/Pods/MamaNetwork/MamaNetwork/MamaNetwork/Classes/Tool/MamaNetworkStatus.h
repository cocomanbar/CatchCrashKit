//
//  MamaNetworkStatus.h
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//  网络监听类
//

#import "UIKit/UIKit.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MamaNetworkStatusType){
    MamaNetworkStatusTypeNone   = 0,    //None
    MamaNetworkStatusTypeWLAN,          //WLAN
    MamaNetworkStatusTypeWIFI,          //wifi
};

typedef NS_ENUM(NSInteger, MamaNetworkStatusWLANType){
    MamaNetworkStatusWLANTypeUnKnow = 0,//未知名网络，比如目前5g或国外小众服务商，需要库维护者升级
    MamaNetworkStatusWLANType2G,
    MamaNetworkStatusWLANType3G,
    MamaNetworkStatusWLANType4G,
    MamaNetworkStatusWLANType5G,
};

extern NSString *const MamaNetworkStatusNotification;

@interface MamaNetworkStatus : NSObject

/**
 初始化单例

 @return [MamaNetworkStatus class]
 */
+ (instancetype)sharedManager;
- (instancetype)init OBJC_UNAVAILABLE("use '+sharedManager' instead");
+ (instancetype)new OBJC_UNAVAILABLE("use '+sharedManager' instead");

/** 当前网络状态 */
@property (nonatomic, assign, readonly) MamaNetworkStatusType networkCurrentStatus;
@property (nonatomic, assign, readonly) MamaNetworkStatusWLANType networkWLANType;

/** 上一次有记录的网络状态 */
@property (nonatomic, assign, readonly) MamaNetworkStatusType networkLastStatus;

/** 获取网络状态返回字符串: wifi、5G、4G、3G、2G、0（0表示不可访问） */
@property (nonatomic ,copy, readonly, nullable) NSString *networkStatusString;


- (void)setHostForPing:(NSString *)host;

/** 启动 */
- (void)setup;

@end

NS_ASSUME_NONNULL_END

