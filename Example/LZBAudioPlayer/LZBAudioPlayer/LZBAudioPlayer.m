//
//  LZBAudioPlayer.m
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/23.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBAudioPlayer.h"
#import "LZBAudioResourceLoader.h"

static LZBAudioPlayer *_instance;

@interface LZBAudioPlayer()
{
    BOOL _isUserPasue;  //是否是用户暂停
}
/**资源播放者播放器*/
@property (nonatomic, strong) AVPlayer *player;

/**资源加载者*/
@property (nonatomic, strong) LZBAudioResourceLoader *resourceLoader;

@end

@implementation LZBAudioPlayer

- (void)playWithURL:(NSURL *)url isSupportCache:(BOOL)isSupportCache
{
     //0.容错
    if([self.currentURL isEqual:url])
    {
        //如果这次播放和上一次一样，说明播放任务存在，存在就继续播放
        [self resume];
        return;
    }
    
    _currentURL = url;
    
    //0.是否需要下载
    if(isSupportCache)
    {
        //加工处理请求
        url = [self.resourceLoader getAudioResourceLoaderSchemeURLWithInPutURL:url];
    }
    //1.资源的请求
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    
    [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];

    
    
    //1.1播放另一之前，必须移除上一个资源组织组者的监听
    if(self.player.currentItem)
        [self removeObservers];
    
    //2.资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    
    //2.1KVO观察
    //组织者组织播放状态
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //组织加载内容
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //2.2通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidInterupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    //3.资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
    
  
}
- (void)pause
{
    [self.player pause];
    _isUserPasue = YES;
    if(self.player)
        self.state = LZBAudioPlayerState_Pause;
}
- (void)resume
{
    [self.player play];
    _isUserPasue = NO;
    //播放器存在并且资源已经加载到可以播放
    if(self.player && self.player.currentItem.playbackLikelyToKeepUp)
    {
        self.state = LZBAudioPlayerState_Playing;
    }
}

- (void)stop
{
    [self pause];
    self.player = nil;
    self.state = LZBAudioPlayerState_Stoped;
}

- (void)seekWithProgress:(CGFloat)progress
{
    if(progress < 0 || progress > 1) return;
    
    //1.获取总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    
    //2.需要播放的进度
    NSTimeInterval playTimeSec = totalTimeSec * progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1.0);
    
    
    //3.播放
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if(finished){
            NSLog(@"拖动到-----%f",CMTimeGetSeconds(currentTime));
            //播放结束的时候，不会自动调用播放，需要手动调用
            [weakSelf resume];
        }
        else
        {
            NSLog(@"取消加载");
        }
    }];
    
}
- (void)seekWithTimeDiffer:(NSTimeInterval)differ
{
      //1.获取总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    
     // 2.获取当前时长
    NSTimeInterval currentTimeSec = [self currentTime];
    
     //3.计算快进和快退时长
    NSTimeInterval result = currentTimeSec + differ;
    if(result < 0) result = 0;
    if(result > totalTimeSec) result =  totalTimeSec;
    
    //4.播放
    [self seekWithProgress:result / totalTimeSec];
}
- (void)setState:(LZBAudioPlayerState)state
{
    if(_state == state) return;
    _state = state;
    //事件传递
    if(self.currentURL.absoluteString.length != 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLZBAudioPlayerURLAndStateChangeNotification object:nil userInfo:@{@"playURL":self.currentURL,@"playState":@(_state)}];
    }
}

//播放结束
- (void)playDidEnd{
    self.state = LZBAudioPlayerState_Stoped;
    NSLog(@"播放结束");
}

//播放被打断
- (void)playDidInterupt
{
    NSLog(@"播放被打断");
    self.state = LZBAudioPlayerState_Pause;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
   if([keyPath isEqualToString:@"status"])
   {
       AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
       
       switch (status) {
           case AVPlayerItemStatusReadyToPlay:
           {
               NSLog(@"准备完毕, 开始播放");
              [self resume];
               break;
           }
           case AVPlayerItemStatusFailed:
           {
               NSLog(@"数据准备失败, 无法播放");
               self.state = LZBAudioPlayerState_Failed;
               break;
           }
               
           default:
               break;
       }
   }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
       
        BOOL keepUp = [change[NSKeyValueChangeNewKey] integerValue];
        if(keepUp)
        {
            //如果不是用户手动暂停，可以播放，用户手动操作级别最高
            if(!_isUserPasue)
            {
                [self resume];
            }
            NSLog(@"资源已经加载的差不多，可以播放了");
        }
        else
        {
            NSLog(@"资源不够，还要继续加载");
            self.state = LZBAudioPlayerState_Loading;
        }
    }
}


#pragma mark- 数据
- (NSTimeInterval)totalTime
{
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if(isnan(totalTimeSec))
        return 0;
    return totalTimeSec;
}
- (NSString *)totalTimeFormat
{
    return [NSString stringWithFormat:@"%02zd:%02zd",(int)self.totalTime/60,(int)self.totalTime%60];
}
- (NSTimeInterval)currentTime
{
    CMTime currentTime = self.player.currentItem.currentTime;
    NSTimeInterval currentTimeSec = CMTimeGetSeconds(currentTime);
    if(isnan(currentTimeSec))
        return 0;
    return currentTimeSec;
}

- (NSString*)currentTimeFormat
{
   return [NSString stringWithFormat:@"%02zd:%02zd",(int)self.currentTime/60,(int)self.currentTime%60];
}

- (float)progress
{
    if(self.totalTime == 0)
        return 0;
    
    return self.currentTime / self.totalTime;
}

- (float)loadProgress
{
   CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    CMTime loadTime =  CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    if(isnan(loadTimeSec))
        return 0;
    return loadTimeSec / self.totalTime;
}


- (void)setRate:(float)rate
{
    self.player.rate = rate;
}
- (float)rate
{
    return self.player.rate;
}
- (void)setMuted:(BOOL)muted
{
    self.player.muted = muted;
}
- (BOOL)muted
{
    return self.player.muted;
}
- (void)setVolume:(float)volume
{
    if(volume < 0 || volume > 1) return;
    
    if(volume > 0)
        [self setMuted:NO];
    
    self.player.volume = volume;
}

- (float)volume{
    return self.player.volume;
}

#pragma mark- pravite
+ (instancetype)shareInstance
{
   if(_instance == nil)
   {
       _instance = [[self alloc]init];
   }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
  if(_instance == nil)
  {
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
          _instance = [super allocWithZone:zone];
      });
  }
    return _instance;
}

- (LZBAudioResourceLoader *)resourceLoader
{
   if(_resourceLoader == nil)
   {
       _resourceLoader = [[LZBAudioResourceLoader alloc]init];
   }
    return _resourceLoader;
}

//移除观察者
- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
