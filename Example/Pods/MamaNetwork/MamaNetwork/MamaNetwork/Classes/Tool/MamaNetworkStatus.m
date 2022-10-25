//
//  MamaNetworkStatus.m
//  MamaNetwork
//
//  Created by mamawangtanxl on 2019/4/15.
//  Copyright © 2019 mamawangtanxl. All rights reserved.
//

#import "MamaNetworkStatus.h"
#import "RealReachability.h"

NSString *const MamaNetworkStatusNotification = @"MamaNetworkStatusNotification";

@interface MamaNetworkStatus ()

@property (nonatomic, assign, readwrite) MamaNetworkStatusWLANType networkWLANType;
@property (nonatomic, assign, readwrite) MamaNetworkStatusType networkCurrentStatus;
@property (nonatomic, assign, readwrite) MamaNetworkStatusType networkLastStatus;
@property (nonatomic, copy  , readwrite) NSString *networkStatusString;
@property (nonatomic, copy) NSString *hostForPing;

@end

@implementation MamaNetworkStatus

#pragma mark - life cycle
static MamaNetworkStatus *_manager = nil;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[MamaNetworkStatus alloc] initSpecially];
    });
    return _manager;
}

- (instancetype)initSpecially {
    self = [super init];
    if (self) {
        _networkStatusString = @"0";
        _hostForPing = @"www.baidu.com";
    }
    return self;
}

#pragma mark -

- (void)setHostForPing:(NSString *)host {
    if ([host isKindOfClass:NSString.class]) {
        _hostForPing = host;
    }
}

- (void)setup
{
    // 添加通知
    [self addNetStatusNotification];
    // 网络监听
    [GLobalRealReachability setHostForPing:_hostForPing];
    [GLobalRealReachability startNotifier];
    // 改变状态
    [self changeStatus:[GLobalRealReachability currentReachabilityStatus] accessType:[GLobalRealReachability currentWWANtype]];
}

- (void)addNetStatusNotification
{
    // 添加网络状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(netWorkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
}

- (void)netWorkChanged:(NSNotification *)notification
{
    // 记录状态
    self.networkLastStatus = self.networkCurrentStatus;
    // 改变状态
    [self changeStatus:[GLobalRealReachability currentReachabilityStatus] accessType:[GLobalRealReachability currentWWANtype]];
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:MamaNetworkStatusNotification object:@(self.networkCurrentStatus)];
}

// 改变状态
- (void)changeStatus:(ReachabilityStatus)status accessType:(WWANAccessType)accessType
{
    if (status == RealStatusUnknown ||
        status == RealStatusNotReachable) {
        self.networkCurrentStatus = MamaNetworkStatusTypeNone;
        self.networkStatusString = @"0";
    }
    else if (status == RealStatusViaWiFi){
        self.networkCurrentStatus = MamaNetworkStatusTypeWIFI;
        self.networkStatusString = @"WIFI";
    }else if (status == RealStatusViaWWAN){
        self.networkCurrentStatus = MamaNetworkStatusTypeWLAN;
        if (accessType == WWANType2G){
            self.networkWLANType = MamaNetworkStatusWLANType2G;
            self.networkStatusString = @"2G";
        }
        else if (accessType == WWANType3G){
            self.networkWLANType = MamaNetworkStatusWLANType3G;
            self.networkStatusString = @"3G";
        }
        else if (accessType == WWANType4G){
            self.networkWLANType = MamaNetworkStatusWLANType4G;
            self.networkStatusString = @"4G";
        }
        else if (accessType == WWANType5G){
            self.networkWLANType = MamaNetworkStatusWLANType5G;
            self.networkStatusString = @"5G";
        }
        else{
            self.networkWLANType = MamaNetworkStatusWLANTypeUnKnow;
            self.networkStatusString = @"0";
        }
    }
}

@end

