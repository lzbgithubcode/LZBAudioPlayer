//
//  LZBAudioPlayer.h
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/23.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

//监听播放状态@"playURL" /@"playState"
#define kLZBAudioPlayerURLAndStateChangeNotification @"LZBAudioPlayerURLAndStateChangeNotification"

typedef NS_ENUM(NSInteger, LZBAudioPlayerState){
    LZBAudioPlayerState_UnKnown = 0, //未知
    LZBAudioPlayerState_Loading = 1, //加载中
    LZBAudioPlayerState_Playing = 2, //播放中
    LZBAudioPlayerState_Stoped  = 3, //停止
    LZBAudioPlayerState_Pause   = 4, //暂停
    LZBAudioPlayerState_Failed  = 5, //失败
   
};

@interface LZBAudioPlayer : NSObject

#pragma  mark - 数据

/**
 是否静音 - 双向
 */
@property (nonatomic, assign) BOOL muted;
/**
 倍速控制 - 双向
 */
@property (nonatomic, assign) float rate;
/**
 音量控制 - 双向
 */
@property (nonatomic, assign) float volume;
/**
 音频总时长
 */
@property (nonatomic, assign, readonly) NSTimeInterval totalTime;
@property (nonatomic, strong, readonly) NSString *totalTimeFormat;
/**
 当前播放时长
 */
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, strong, readonly) NSString *currentTimeFormat;
/**
 当前播放进度
 */
@property (nonatomic, assign, readonly) float progress;
/**
 当前加载进度
 */
@property (nonatomic, assign, readonly) float loadProgress;
/**
 当前播放URL
 */
@property (nonatomic, strong, readonly) NSURL *currentURL;

/**
 当前播放播放状态
 */
@property (nonatomic, assign, readonly) LZBAudioPlayerState state;



#pragma mark - API
//单例
+ (instancetype)shareInstance;

/**
   播放url  isSupportCache：是否要下载缓存
 */
- (void)playWithURL:(NSURL *)url isSupportCache:(BOOL)isSupportCache;

/**
   暂停
 */
- (void)pause;

/**
  继续播放
 */
- (void)resume;

/**
 停止
 */
- (void)stop;

/**
 快进  快退 differ
 */
- (void)seekWithTimeDiffer:(NSTimeInterval)differ;

/**
 指定播放进度播放
 */
- (void)seekWithProgress:(CGFloat)progress;



@end
