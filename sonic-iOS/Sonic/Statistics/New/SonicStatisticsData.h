//
//  SonicStatisticsData.h
//  Sonic
//
//  Created by peiyu wang on 2022/1/2.
//  Copyright © 2022 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SonicCacheErrorCode)
{
    SonicCacheErrorCode_Idle            = 0,    // 操作初始状态
    SonicCacheErrorCode_Success         = 1,    // 操作成功
    SonicCacheErrorCode_DataIllegal     = -101, // 操作失败 - sonic缓存数据非法
    SonicCacheErrorCode_FileFailed      = -102, // 操作失败 - 文件操作失败
    SonicCacheErrorCode_VerifyShaFailed = -103  // 操作失败 - Sha校验失败
};

typedef NS_ENUM(NSInteger, SonicResultCode)
{
    SonicResultCode_FirstLoad      = 1,  // 首次加载页面
    SonicResultCode_TemplateChange = 2,  // 二次进入页面模版修改
    SonicResultCode_DataUpdate     = 3,  // 二次进入页面数据修改
    SonicResultCode_NotModified    = 4,  // 二次进入页面数据和缓存一致
    SonicResultCode_HTTPFailed     = -1, // sonic流程中断 - 网络请求失败
    SonicResultCode_RspIllegal     = -2, // sonic流程中断 - 回包数据非法
};

@interface SonicStatisticsData : NSObject
/// sonic模式
@property (nonatomic, assign) NSInteger sonicMode;
/// sonic请求响应码
@property (nonatomic, assign) NSInteger rspCode;
/// 是否触发Sonic存储的阈值上限
@property (nonatomic, assign) BOOL isTrimCache;
/// 读取Sonic缓存结果code
@property (nonatomic, assign) SonicCacheErrorCode readSonicCacheCode;
/// 写Sonic缓存结果code
@property (nonatomic, assign) SonicCacheErrorCode writeSonicCacheCode;
/// Sonic结果Code
@property (nonatomic, assign) SonicResultCode resultCode;
@end

NS_ASSUME_NONNULL_END
