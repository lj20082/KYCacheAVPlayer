//
//  KYPlayerView.m
//  VIMediaCacheDemo
//
//  Created by 李建忠 on 2018/5/27.
//  Copyright © 2018年 Vito. All rights reserved.
//

#import "KYPlayerView.h"

@implementation KYPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity{
    _videoGravity = videoGravity;
    ((AVPlayerLayer *)[self layer]).videoGravity = videoGravity;
}

@end
