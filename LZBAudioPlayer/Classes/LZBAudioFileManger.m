//
//  LZBAudioFileManger.m
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/25.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBAudioFileManger.h"
//获取contentType
#import <MobileCoreServices/MobileCoreServices.h>
/**
 获取存取音频路径
 */
static NSString *lzb_tempAudioPath = @"/LZBAudioPlayer_Temp"; //临时文件夹路径
static NSString *lzb_saveAudioPath = @"/LZBAudioPlayer_Save";  //完成文件夹路径

@implementation LZBAudioFileManger
+ (BOOL)cacheFileExitWithURL:(NSURL *)url;
{
    NSString *cachePath = [self cacheFilePathWithURL:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}
+ (NSString *)cacheFilePathWithURL:(NSURL*)url
{
    NSString *cachePath = [[self getFileFolderCachePath] stringByAppendingPathComponent:url.lastPathComponent];
    return cachePath;
}
+ (long long)cacheFileSizeWithURL:(NSURL*)url
{
    //1.如果文件不存在，直接返回0
    if(![self cacheFileExitWithURL:url]) return 0;
    //2.如果文件存在，获取路径
    NSString *cachePath = [self cacheFilePathWithURL:url];
    //3.获取文件属性，文件大小
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
    return [fileInfo[NSFileSize] longLongValue];
}

+ (long long)cacheFreeDiskSpace
{
    NSDictionary *cacheInfo = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[self getFileFolderCachePath] error:nil];
    return [cacheInfo[NSFileSystemFreeSize] longLongValue];
}


+ (BOOL)tempFileExitWithURL:(NSURL *)url
{
    NSString *cachePath = [self tempFilePathWithURL:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath];
}

+ (NSString *)tempFilePathWithURL:(NSURL*)url
{
    NSString *cachePath = [[self getFileFolderTempPath] stringByAppendingPathComponent:url.lastPathComponent];
    return cachePath;
}

+ (long long)tempFileSizeWithURL:(NSURL*)url
{
    //1.如果文件不存在，直接返回0
    if(![self tempFileExitWithURL:url]) return 0;
    //2.如果文件存在，获取路径
    NSString *cachePath = [self tempFilePathWithURL:url];
    //3.获取文件属性，文件大小
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
    return [fileInfo[NSFileSize] longLongValue];
    
}

+ (void)removeTempWithURL:(NSURL*)url
{
    NSString *tempPath = [self tempFilePathWithURL:url];
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

+ (long long)tempFreeDiskSpace
{
   NSDictionary *tempInfo = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [tempInfo[NSFileSystemFreeSize] longLongValue];
}

+ (void)moveFileToCacheWithURL:(NSURL*)url
{
    if(![self tempFileExitWithURL:url]) return;
    NSString *tempPath = [self tempFilePathWithURL:url];
    NSString *cachePath = [self cacheFilePathWithURL:url];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       [[NSFileManager defaultManager] moveItemAtPath:tempPath toPath:cachePath error:nil]; 
    });
    
}


+ (NSString *)contentTypeWithURL:(NSURL*)url
{
    NSString *cachePath = [self cacheFilePathWithURL:url];
    NSString *fileExtension = cachePath.pathExtension;
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef _Nonnull)(fileExtension) , NULL);
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    return contentType;
}




#pragma mark- pravite 

+(NSString *)getFileFolderCachePath
{
    NSFileManager *manger = [NSFileManager defaultManager];
    
    //创建路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:lzb_saveAudioPath];
    
    //如果文件路径不存在，那么就创建文件夹
    if(![manger fileExistsAtPath:path])
    {
        [manger createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

+(NSString *)getFileFolderTempPath
{
    NSFileManager *manger = [NSFileManager defaultManager];
    
    //创建路径
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:lzb_tempAudioPath];
    
    //如果文件路径不存在，那么就创建文件夹
    if(![manger fileExistsAtPath:path])
    {
        [manger createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}
@end
