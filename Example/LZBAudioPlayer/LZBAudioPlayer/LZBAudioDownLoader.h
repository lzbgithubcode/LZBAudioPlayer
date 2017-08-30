//
//  LZBAudioDownLoader.h
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/26.
//  Copyright © 2017年 Apple. All rights reserved.
// 下载器，下载某个区间的数据

#import <AVFoundation/AVFoundation.h>
@class LZBAudioDownLoader;

@protocol LZBAudioDownLoaderDelegate <NSObject>

@optional
/**
 接受到响应头，并开始下载 传输需要请求文件的总大小
 
 @param downLoader 下载器
 @param totalSize 文件大小
  @param mineType 文件类型
 */
- (void)downLoader:(LZBAudioDownLoader *)downLoader didReceiveResponseHeader:(long long)totalSize  mineType:(NSString *)mineType;;


/**
 接收到数据，下载过程中传递获取到的数据和已经下载数据的长度以及临时文件存储路径

 @param downLoader 下载器
 @param data 下载的数据
 @param downloadedSize 已经下载的数据大小
 @param tempPath 临时文件存放路径
 */
- (void)downLoader:(LZBAudioDownLoader *)downLoader didReceiveData:(NSData *)data downloadedSize:(long long)downloadedSize tempPath:(NSString *)tempPath;

/**
 下载完成，传输保存的路径
 
 @param downLoader 下载器
 @param saveFilePath 保存文件存储路径
 */
- (void)downLoader:(LZBAudioDownLoader *)downLoader didSuccessDownLoadedWithFileSavePath:(NSString *)saveFilePath;

/**
 下载失败，传输错误信息
 
 @param downLoader 下载器
 @param error 传输错误信息
 */
- (void)downLoader:(LZBAudioDownLoader *)downLoader didFailDownLoadedWithError:(NSError *)error;

@end

@interface LZBAudioDownLoader : NSObject

/**
 下载器监听
 */
@property (nonatomic, weak) id <LZBAudioDownLoaderDelegate> downLoaderDelegate;

/**
 已经下载文件的大小
 */
@property (nonatomic, assign, readonly)  long long  downLoadSize;

/**
 记录区间的起始位置
 */
@property (nonatomic, assign, readonly) CGFloat startOffset;

/**
  需要下载文件的总大小
 */
@property (nonatomic, assign, readonly) CGFloat totalSize;

/**
 需要下载文件的MineType
 */
@property (nonatomic, copy, readonly) NSString *mineType;

/**
 传递要下载的文件的URL和下载初始偏移量, 这个方法功能是从网络请求数据，并把数据保存到本地的一个临时文件.
 * 当网络请求结束或取消的时候，如果数据完整，则把数据缓存到指定的路径，不完整就删除
 @param url URL
 @param offset 下载起点
 */
- (void)downLoaderWithURL:(NSURL *)url offset:(long long)offset;


/**
 * 取消当前下载进程
 */
- (void)invalidateAndCancel;

/**
 * 取消并且移除临时数据
 */
- (void)invalidateAndClean;

@end
