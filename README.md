# LZBAudioPlayer

[![CI Status](http://img.shields.io/travis/lzbgithubcode/LZBAudioPlayer.svg?style=flat)](https://travis-ci.org/lzbgithubcode/LZBAudioPlayer)
[![Version](https://img.shields.io/cocoapods/v/LZBAudioPlayer.svg?style=flat)](http://cocoapods.org/pods/LZBAudioPlayer)
[![License](https://img.shields.io/cocoapods/l/LZBAudioPlayer.svg?style=flat)](http://cocoapods.org/pods/LZBAudioPlayer)
[![Platform](https://img.shields.io/cocoapods/p/LZBAudioPlayer.svg?style=flat)](http://cocoapods.org/pods/LZBAudioPlayer)

## 简单介绍

LZBAudioPlayer完整封装了音频播放器的逻辑，没有设置播放器的UI部分，所以你可以完全自定义UI，并且你可以访问播放的业务方法或者状态来更改UI的样式
* 支持在线播放音频
* 支持下载播放音频
* 支持边下载边播放

## 类的介绍
* LZBAudioPlayer   播放器
* LZBAudioFileManger   下载文件管理，负责管理文件下载，下载文件在temp文件中下载，下载完成并文件完好保存在cache文件中
* LZBAudioDownLoader  音频下载器，负责下载区间音频
* LZBAudioResourceLoader 请求资源类
   

## 使用CocoaPods导入

```ruby
pod "LZBAudioPlayer"
```

## 手动导入

将`LZBAudioPlayer`文件夹中的所有源代码拽入项目中

导入主头文件：`#import "LZBAudioPlayer.h"`


## 你可以使用的方法

```objc

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


```


## 详细解说
简书地址：[边下载边缓存的音频播放器AVPlayer](http://www.jianshu.com/p/042162ab9cc1)


## 联系作者
* QQ : 1835064412
* 简书：[摸着石头过河_崖边树](http://www.jianshu.com/u/268ed1ef819e)
* email:1835064412@qq.com

## Author

lzbgithubcode, 1835064412@qq.com

## 期待
* 如果在使用过程中遇到BUG，希望你能联系我，谢谢
* 如果您觉得这个这个demo对您有所帮助，请给我一颗❤️❤️,star一下
* 如果你想了解更多的开源姿势，可以关注公众号‘开发者源代码’

![image](https://github.com/lzbgithubcode/LZBAudioPlayer/raw/master/screenshotImage/developerCoder08.jpg)






