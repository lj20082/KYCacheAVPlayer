//
//  KYPlayerView.h
//  VIMediaCacheDemo
//
//  Created by 李建忠 on 2018/5/27.
//  Copyright © 2018年 Vito. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

@interface KYPlayerView : UIView

@property (nonatomic,assign) AVLayerVideoGravity videoGravity;

- (AVPlayerLayer *)playerLayer;

- (void)setPlayer:(AVPlayer *)player;

@end
