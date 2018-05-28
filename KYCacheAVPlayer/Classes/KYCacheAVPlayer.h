//
//  KYCacheAVPlayer.h
//  VIMediaCacheDemo
//
//  Created by 李建忠 on 2018/5/27.
//  Copyright © 2018年 Vito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KYPlayerView.h"

typedef NS_ENUM(NSInteger, KYAVPlayerStatus) {
    KYAVPlayerStatusReadyToPlay = 0, // 准备好播放
    KYAVPlayerStatusLoadingVideo,    // 加载视频
    KYAVPlayerStatusPlayEnd,         // 播放结束
    KYAVPlayerStatusCacheData,       // 缓冲视频
    KYAVPlayerStatusCacheEnd,        // 缓冲结束
    KYAVPlayerStatusPlayStop,        // 播放中断 （多是没网）
    KYAVPlayerStatusItemFailed,      // 视频资源问题
    KYAVPlayerStatusEnterBack,       // 进入后台
    KYAVPlayerStatusBecomeActive,    // 从后台返回
};

@protocol KYCacheAVPlayerDeleagte<NSObject>
@optional
- (void)kyAVPlayerStatusChanged:(KYAVPlayerStatus)status;
@end

@interface KYCacheAVPlayer : NSObject

@property (nonatomic, strong) KYPlayerView *playerView;

@property (nonatomic,assign) id<KYCacheAVPlayerDeleagte> delegate;

// 是否支持循环播放，默认为NO
@property (nonatomic,assign) BOOL supportCycleplay;

+ (instancetype)sharedInstance;

- (void)playVideoWithURL:(NSURL *)url;
// 如果url没有变化则调用resume方法，如果变化了则调用playVideoWithURL重新开始播放
- (void)resumeVideoIfNeedWithURL:(NSURL *)url;
// 停止播放，暂停缓冲
- (void)stopPlay;
// 如果当前状态是暂停，则恢复播放，如果当前状态是播放，则暂停
- (void)pauseOrResume;
// 暂停操作
- (void)pause;
// 恢复播放
- (void)resume;

@end
