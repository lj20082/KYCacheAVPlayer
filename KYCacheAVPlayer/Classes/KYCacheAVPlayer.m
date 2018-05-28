//
//  KYCacheAVPlayer.m
//  VIMediaCacheDemo
//
//  Created by 李建忠 on 2018/5/27.
//  Copyright © 2018年 Vito. All rights reserved.
//

#import "KYCacheAVPlayer.h"
#import "VIMediaCache.h"

@interface KYCacheAVPlayer()

@property (nonatomic, strong) VIResourceLoaderManager *resourceLoaderManager;

@property (copy, nonatomic) NSURL *currentPlayURL;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic) CMTime duration;

@property (nonatomic, strong) VIMediaDownloader *downloader;
@property (nonatomic,assign) BOOL shouldAutoResume; //是否应该主动恢复，当非用户主动暂停操作造成播放暂停的需要自动恢复播放
@end

@implementation KYCacheAVPlayer

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    if (self = [super init]) {
        [self addNotificatonForPlayer];
        VIResourceLoaderManager *resourceLoaderManager = [VIResourceLoaderManager new];
        self.resourceLoaderManager = resourceLoaderManager;
        self.playerView = [[KYPlayerView alloc] init];
    }
    return self;
}

- (void)playVideoWithURL:(NSURL *)url{
    [self.player pause];
    if (self.playerItem) {
        [self removeObserverWithPlayItem:self.playerItem];
        [self.resourceLoaderManager cancelLoaders];
    }
    self.currentPlayURL = url;
    AVPlayerItem *playerItem = [self.resourceLoaderManager playerItemWithURL:url];
    self.playerItem = playerItem;
    [self addObserverWithPlayItem:self.playerItem];
    if (!self.player) {
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        if (@available(iOS 11.0, *)) {
            player.automaticallyWaitsToMinimizeStalling = NO;
        }
        self.player = player;
        [self.playerView setPlayer:self.player];
    }else{
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
    }
    [self.player play];
}

- (void)resumeVideoIfNeedWithURL:(NSURL *)url{
    if ([url isEqual:self.currentPlayURL]) {
        [self resume];
    }else{
        [self playVideoWithURL:url];
    }
}

- (void)stopPlay{
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    if (self.playerItem) {
        [self removeObserverWithPlayItem:self.playerItem];
        [self.resourceLoaderManager cancelLoaders];
        self.playerItem = nil;
    }
}

- (void)pauseOrResume{
    if (self.player.rate > 0.0) {
        [self.player pause];
    } else {
        [self.player play];
    }
}

- (void)pause{
    if (self.player.rate > 0.0) {
        [self.player pause];
    }
}

- (void)resume{
    if (self.player.rate == 0.0) {
        [self.player play];
    }
}

/**
 *  返回 当前 视频 播放时长
 */
- (double)getCurrentPlayingTime{
    return self.player.currentTime.value/self.player.currentTime.timescale;
}

/**
 *  返回 当前 视频 缓存时长
 */
- (NSTimeInterval)availableDuration{
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    
    return result;
}

- (void)notifyStatusChangedIfNeed:(KYAVPlayerStatus)status{
    if ([self.delegate respondsToSelector:@selector(kyAVPlayerStatusChanged:)]) {
        [self.delegate kyAVPlayerStatusChanged:status];
    }
}

- (void)addObserverWithPlayItem:(AVPlayerItem *)item
{
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}
/** 移除 item 的 observer */
- (void)removeObserverWithPlayItem:(AVPlayerItem *)item
{
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}
/** 数据处理 获取到观察到的数据 并进行处理 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AVPlayerItem *item = object;
    if ([keyPath isEqualToString:@"status"]) {// 播放状态
        [self handleStatusWithPlayerItem:item];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {// 跳转后没数据
        [self notifyStatusChangedIfNeed:KYAVPlayerStatusCacheData];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {// 跳转后有数据
        [self notifyStatusChangedIfNeed:KYAVPlayerStatusCacheEnd];
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"已缓存时长 : %f,当前播放时长： %f",timeInterval,self.getCurrentPlayingTime);
        if(self.shouldAutoResume){
            if (timeInterval > self.getCurrentPlayingTime + 5 || timeInterval >= CMTimeGetSeconds(self.duration)){
                [self resume];
            }
        }
    }
}
/**
 处理 AVPlayerItem 播放状态
 AVPlayerItemStatusUnknown           状态未知
 AVPlayerItemStatusReadyToPlay       准备好播放
 AVPlayerItemStatusFailed            播放出错
 */
- (void)handleStatusWithPlayerItem:(AVPlayerItem *)item
{
    AVPlayerItemStatus status = item.status;
    switch (status) {
        case AVPlayerItemStatusReadyToPlay:{
            NSLog(@"AVPlayerItemStatusReadyToPlay");
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
                NSLog(@"duration: %f",duration);
            });
            [self notifyStatusChangedIfNeed:KYAVPlayerStatusReadyToPlay];
        }
            break;
        case AVPlayerItemStatusFailed:{
            NSLog(@"AVPlayerItemStatusFailed");
            [self notifyStatusChangedIfNeed:KYAVPlayerStatusItemFailed];
            break;
        }
        case AVPlayerItemStatusUnknown:{
            NSLog(@"AVPlayerItemStatusUnknown");
            break;
        }
        default:
            break;
    }
}

/**
 添加关键通知
 
 AVPlayerItemDidPlayToEndTimeNotification     视频播放结束通知
 AVPlayerItemTimeJumpedNotification           视频进行跳转通知
 AVPlayerItemPlaybackStalledNotification      视频异常中断通知
 UIApplicationDidEnterBackgroundNotification  进入后台
 UIApplicationDidBecomeActiveNotification     返回前台
 
 */
- (void)addNotificatonForPlayer{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(videoPlayEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayError:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayEnterBack:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
/** 移除 通知 */
- (void)removeNotification{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [center removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [center removeObserver:self];
}

/** 视频播放结束 */
- (void)videoPlayEnd:(NSNotification *)notic{
    NSLog(@"视频播放结束");
    [self notifyStatusChangedIfNeed:KYAVPlayerStatusPlayEnd];
    [self.player seekToTime:kCMTimeZero];
    if (self.supportCycleplay) {
        [self.player play];
    }
}

/** 视频异常中断 */
- (void)videoPlayError:(NSNotification *)notic
{
    self.shouldAutoResume = YES;
    [self notifyStatusChangedIfNeed:KYAVPlayerStatusCacheData];
}
/** 进入后台 */
- (void)videoPlayEnterBack:(NSNotification *)notic
{
    NSLog(@"进入后台");
    [self notifyStatusChangedIfNeed:KYAVPlayerStatusEnterBack];
}
/** 返回前台 */
- (void)videoPlayBecomeActive:(NSNotification *)notic
{
    NSLog(@"返回前台");
    [self notifyStatusChangedIfNeed:KYAVPlayerStatusBecomeActive];
}

@end
