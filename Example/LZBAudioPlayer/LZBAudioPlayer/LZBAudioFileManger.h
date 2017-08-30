//
//  LZBAudioFileManger.h
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/25.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LZBAudioFileManger : NSObject

#pragma mark - Cache操作
/**
 根据URL,判断Cache文件是否存在

 @param url URL
 */
+ (BOOL)cacheFileExitWithURL:(NSURL *)url;

/**
 根据URL获取文件Cache路径

 @param url URL
 @return 文件路径
 */
+ (NSString *)cacheFilePathWithURL:(NSURL*)url;

/**
 根据URL获取文件Cache的大小
 
 @param url URL
 @return 文件路径
 */
+ (long long)cacheFileSizeWithURL:(NSURL*)url;

/**
 获取cache文件剩余空间
 */
+ (long long)cacheFreeDiskSpace;



#pragma mark - temp操作
/**
 根据URL,判断Temp文件是否存在
 
 @param url URL
 */
+ (BOOL)tempFileExitWithURL:(NSURL *)url;

/**
 根据URL获取文件Temp路径
 
 @param url URL
 @return 文件路径
 */
+ (NSString *)tempFilePathWithURL:(NSURL*)url;

/**
 根据URL获取文件Temp的大小
 
 @param url URL
 @return 文件路径
 */
+ (long long)tempFileSizeWithURL:(NSURL*)url;
/**
 根据URL移除文件
 
 @param url URL
 */
+ (void)removeTempWithURL:(NSURL*)url;

/**
 获取temp文件剩余空间
 */
+ (long long)tempFreeDiskSpace;



#pragma mark - common操作

/**
 根据URL移动文件 temp - > cache
 
 @param url URL
 */
+ (void)moveFileToCacheWithURL:(NSURL*)url;


/**
 根据URL获取contentType
 
 @param url URL
 @return 文件路径
 */
+ (NSString *)contentTypeWithURL:(NSURL*)url;



@end
