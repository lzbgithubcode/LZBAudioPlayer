//
//  LZBAudioDownLoader.m
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/26.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBAudioDownLoader.h"
#import "LZBAudioFileManger.h"

#define TIME_OUT_INTERVAL   10.0  //超时时间

@interface LZBAudioDownLoader()<NSURLSessionDataDelegate>
/**请求会话*/
@property (nonatomic, strong)  NSURLSession *session;
/**记录请求的URL*/
@property (nonatomic, strong) NSURL *url;
/**输出流*/
@property (nonatomic, strong)  NSOutputStream *outputStream;
/**请求超时记录*/
@property (nonatomic, assign) BOOL timeOutOnce;


@end

@implementation LZBAudioDownLoader

- (void)downLoaderWithURL:(NSURL *)url offset:(long long)offset
{
     self.url = url;
     self.startOffset = offset;
    
    //如果之前存在下载，先清空下载
    if(self.session != nil)
    {
        [self invalidateAndClean];
    }
    
    //1.创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIME_OUT_INTERVAL];
    
    //1.1确定请求区间
     [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    
    //2.创建请求任务
     NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    
    //3.开始任务
    [dataTask resume];
    
}

- (void)invalidateAndCancel
{
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)invalidateAndClean
{
    [self invalidateAndCancel];
    self.downLoadSize = 0;
    [LZBAudioFileManger removeTempWithURL:self.url];
}



#pragma mark - NSURLSessionDataDelegate
//请求头返回请求信息，可以控制请求是否继续
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
  didReceiveResponse:(NSHTTPURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{

    //1.从响应头里面取出文件大小数据，但是 先从Content-Length 中取，让后在Content-Range中取Content-Range比较准确，但是如果没有range,就没有这个字段
    self.totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeString = response.allHeaderFields[@"Content-Range"];
    if(contentRangeString.length != 0)
        self.totalSize = [[contentRangeString componentsSeparatedByString:@"/"].lastObject longLongValue];
    
    self.mineType = response.MIMEType;
    //1.1判断文件是否有剩余空间，如果没有就取消下载
    if([LZBAudioFileManger tempFreeDiskSpace] < self.totalSize)
    {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    
    //1.2.如果空间充足,可以继续下载
    if([self.downLoaderDelegate respondsToSelector:@selector(downLoader:didReceiveResponseHeader: mineType:)])
    {
        [self.downLoaderDelegate downLoader:self didReceiveResponseHeader:self.totalSize mineType:self.mineType];
    }
    //2.打开输出录
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

// 接收到服务器返回数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    self.downLoadSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    if([self.downLoaderDelegate respondsToSelector:@selector(downLoader:didReceiveData:downloadedSize:tempPath:)])
    {
        [self.downLoaderDelegate downLoader:self didReceiveData:data downloadedSize:self.downLoadSize tempPath:[LZBAudioFileManger tempFilePathWithURL:self.url]];
    }
}

//请求结束的时候调用，成功和失败都会调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if(error == nil)  //下载成功
        [self downloadSuccessWithURLSession:session];
    else   //下载失败
        [self downloadFailWithError:error];
    
    //关闭流
    [self.outputStream close];
    self.outputStream = nil;
}

//下载成功
-(void)downloadSuccessWithURLSession:(NSURLSession *)session
{
   //1.判断文件是否完整，如果完整，就从temp - 移动到cache
    if(self.totalSize == [LZBAudioFileManger tempFileSizeWithURL:self.url])
    {
        [LZBAudioFileManger moveFileToCacheWithURL:self.url];
    }
    else
    {
         //不完整
    }
    
    //代理回调数据
    if([self.downLoaderDelegate respondsToSelector:@selector(downLoader:didSuccessDownLoadedWithFileSavePath:)])
    {
        [self.downLoaderDelegate downLoader:self didSuccessDownLoadedWithFileSavePath:[LZBAudioFileManger cacheFilePathWithURL:self.url]];
    }
    
}

//下载失败
- (void)downloadFailWithError:(NSError *)error
{
    //网络中断：-1005
    //无网络连接：-1009
    //请求超时：-1001
    //服务器内部错误：-1004
    //找不到服务器：-1003
    
    if(error.code == -1001 && !self.timeOutOnce)
    {
        // 网络超时，重连一次
        __weak typeof(self) weakSelf = self;
        NSLog(@"下载失败-----%@",error);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.timeOutOnce = YES;
            [weakSelf downLoaderWithURL:weakSelf.url offset:weakSelf.startOffset];
        });
        return;
    }
    
    NSString *localMessage = error.userInfo[@"NSLocalizedDescription"];
    NSError *failError = [NSError errorWithDomain:localMessage code:error.code userInfo:error.userInfo];
    NSLog(@"下载失败-----%@",failError);
    
    //代理回调数据
    if([self.downLoaderDelegate respondsToSelector:@selector(downLoader:didFailDownLoadedWithError:)])
    {
        [self.downLoaderDelegate downLoader:self didFailDownLoadedWithError:failError];
    }
}

#pragma mark- lazy
- (void)setDownLoadSize:(long long)downLoadSize
{
    _downLoadSize = downLoadSize;
}
- (void)setStartOffset:(CGFloat)startOffset
{
    _startOffset = startOffset;
}
- (void)setTotalSize:(CGFloat)totalSize
{
    _totalSize = totalSize;
}
- (void)setMineType:(NSString *)mineType
{
    _mineType = mineType;
}

- (NSURLSession *)session
{
  if(_session == nil)
  {
      _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue: [NSOperationQueue mainQueue]];
  }
    return _session;
}

- (NSOutputStream *)outputStream
{
  if(_outputStream == nil)
  {
      _outputStream = [NSOutputStream outputStreamToFileAtPath:[LZBAudioFileManger tempFilePathWithURL:self.url] append:YES];
  }
    return _outputStream;
}
@end
