//
//  KYViewController.m
//  KYCacheAVPlayer
//
//  Created by 673637753@qq.com on 05/27/2018.
//  Copyright (c) 2018 673637753@qq.com. All rights reserved.
//

#import "KYViewController.h"
#import "KYCacheAVPlayer.h"

@interface KYViewController ()<KYCacheAVPlayerDeleagte>

@end

@implementation KYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // 初始化

    NSURL *url = [NSURL URLWithString:@"http://p11s9kqxf.bkt.clouddn.com/bianche.mp4"];
    [KYCacheAVPlayer sharedInstance].delegate = self;
    [[KYCacheAVPlayer sharedInstance] playVideoWithURL:url];
    [KYCacheAVPlayer sharedInstance].playerView.videoGravity = AVLayerVideoGravityResize;
    [self.view addSubview:[KYCacheAVPlayer sharedInstance].playerView];
    [[KYCacheAVPlayer sharedInstance].playerView setFrame:self.view.bounds];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url2 = [NSURL URLWithString:@"http://p11s9kqxf.bkt.clouddn.com/bianche.mp4"];
        [[KYCacheAVPlayer sharedInstance] playVideoWithURL:url2];
    });
    return;
    // 切换
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url2 = [NSURL URLWithString:@"https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4"];
        [[KYCacheAVPlayer sharedInstance] playVideoWithURL:url2];
    });
    // 暂停
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[KYCacheAVPlayer sharedInstance] pause];
    });
    // 恢复相同地址，则继续播放
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url2 = [NSURL URLWithString:@"https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4"];
        [[KYCacheAVPlayer sharedInstance] resumeVideoIfNeedWithURL:url2];
    });
    // 暂停
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[KYCacheAVPlayer sharedInstance] pause];
    });
    // 恢复不同地址，则重新新的地址播放
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url2 = [NSURL URLWithString:@"http://p11s9kqxf.bkt.clouddn.com/bianche.mp4"];
        [[KYCacheAVPlayer sharedInstance] resumeVideoIfNeedWithURL:url2];
    });
}

// 状态监听 -》 通过委托实现
- (void)kyAVPlayerStatusChanged:(KYAVPlayerStatus)status{
    NSLog(@"status: %ld",(long)status);
}
/// 注意页面消失时按需要是否应该移除delegate，防止在其他页面播放回调此处委托
@end
