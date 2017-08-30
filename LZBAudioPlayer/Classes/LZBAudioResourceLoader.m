//
//  LZBAudioResourceLoader.m
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/25.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "LZBAudioResourceLoader.h"
#import "LZBAudioFileManger.h"
#import "LZBAudioDownLoader.h"

@interface LZBAudioResourceLoader() <LZBAudioDownLoaderDelegate>

/**保存处理前的URL*/
@property(nonatomic, strong) NSURL *inputURL;

/**下载器*/
@property (nonatomic, strong) LZBAudioDownLoader *downLoader;
/**下载数据请求数组*/
@property (nonatomic, strong) NSMutableArray *downLoadedDataRequests;
@end


@implementation LZBAudioResourceLoader

#pragma mark - AVAssetResourceLoaderDelegate

/**
 *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理，准备好的资源可以直接拿给外界使用
 *  @param resourceLoader 资源管理器
 *  @param loadingRequest 每一小块数据的请求
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    
    //1.如果Cache资源已经存在，那么就结束请求，并把资源给外界 retern
    if([LZBAudioFileManger cacheFileExitWithURL:self.inputURL])
    {
        [self handleLocationCacheLoadingRequest:loadingRequest];
        return  YES;
    }

    long long requireStartOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    if(requireStartOffset != currentOffset)
        requireStartOffset = currentOffset;
    
    [self.downLoadedDataRequests addObject:loadingRequest];
    
    NSLog(@"=====%@",loadingRequest);
    //2.如果Cache资源不存在，那么temp中是否已经有加载，如果不存在，那么直接从头开始加载 retern
    if(self.downLoader.downLoadSize == 0)
    {
        //从头开始加载
        [self.downLoader downLoaderWithURL:self.inputURL offset:requireStartOffset];
        return YES;
    }
    
    
    //3.判断是否需要重新下载
    //3.1 请求开始点 < 已经下载资源的开始点
    //3.2 请求开始点 > 已经下载资源的开始点 + 长度 + 多一段长度（自定义100）
     if(requireStartOffset < self.downLoader.startOffset  || self.downLoader.startOffset + self.downLoader.downLoadSize + 100 < requireStartOffset)
     {
         [self.downLoader invalidateAndClean];
         [self.downLoader downLoaderWithURL:self.inputURL offset:requireStartOffset];
         return YES;
     }
     //4.不需要重新加载，就继续加载，并且把已经加载好的数据给外界
    [self hanleAllLoadingRequests];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"这个请求请求完成");
    [self.downLoadedDataRequests removeObject:loadingRequest];
}

#pragma mark - LZBAudioDownLoaderDelegate
//下载数据中
- (void)downLoader:(LZBAudioDownLoader *)downLoader didReceiveData:(NSData *)data downloadedSize:(long long)downloadedSize tempPath:(NSString *)tempPath
{
    [self hanleAllLoadingRequests];
}



#pragma mark - handle

//处理加载请求
- (void)hanleAllLoadingRequests
{
    NSMutableArray *deleteRequests = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.downLoadedDataRequests) {

        //1.填充请求信息
        [self processFillRequestInfomation:loadingRequest];
        
        //2.把加载好的数据响应给外界,填充数据
        BOOL compeletion = [self processRequestDataCompeletionResponse:loadingRequest];
        //3.完成本次请求加载
        if(compeletion)
        {
            [loadingRequest finishLoading];
            [deleteRequests addObject:loadingRequest];
        }
    }
    
    [self.downLoadedDataRequests removeObjectsInArray:deleteRequests];
}

//填充信息头信息
- (void)processFillRequestInfomation:(AVAssetResourceLoadingRequest *)loadingRequest
{
    long long totalSize = self.downLoader.totalSize;
    NSString *contentType = self.downLoader.mineType;
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    loadingRequest.contentInformationRequest.contentType = contentType;
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
}

//填充数据是否完成
- (BOOL)processRequestDataCompeletionResponse:(AVAssetResourceLoadingRequest *)loadingRequest
{
    long long requestedOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    long long requestedLength = loadingRequest.dataRequest.requestedLength;
    if(currentOffset != 0)
        requestedOffset = currentOffset;
    
    NSData *data = [NSData dataWithContentsOfFile:[LZBAudioFileManger tempFilePathWithURL:self.inputURL] options:NSDataReadingMappedIfSafe error:nil];
    if(data == nil)
    {
       data = [NSData dataWithContentsOfFile:[LZBAudioFileManger cacheFilePathWithURL:self.inputURL] options:NSDataReadingMappedIfSafe error:nil];
    }
    
    long long responseOffset = requestedOffset - self.downLoader.startOffset;
    long long responseLength = MIN(self.downLoader.startOffset + self.downLoader.downLoadSize - requestedOffset, requestedLength);
    NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
    [loadingRequest.dataRequest respondWithData:subData];
    return requestedLength == responseLength;
}


//处理本地加载请求
- (void)handleLocationCacheLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    //1.填充请求信息
    long long totalSize = [LZBAudioFileManger cacheFileSizeWithURL:self.inputURL];
    //是否主持多段加载
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    loadingRequest.contentInformationRequest.contentType = [LZBAudioFileManger contentTypeWithURL:self.inputURL];
    
    
    //2.把数据给外界
    NSData *data = [NSData dataWithContentsOfFile:[LZBAudioFileManger cacheFilePathWithURL:self.inputURL] options:NSDataReadingMappedIfSafe error:nil];
    long long requestedOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestedLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestedOffset, requestedLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    //3.结束请求
    [loadingRequest finishLoading];
}


#pragma mark - pravite

- (NSURL *)getAudioResourceLoaderSchemeURLWithInPutURL:(NSURL *)inputURL
{
    //只有改变加载地址的Scheme,请求代理方法才会执行
    if(inputURL.absoluteString.length == 0) return nil;
    self.inputURL = inputURL; //保存URL，加载数据需要使用
    NSURLComponents *componment = [NSURLComponents componentsWithURL:inputURL resolvingAgainstBaseURL:NO];
    componment.scheme = @"streaming";
    return componment.URL;
}

- (LZBAudioDownLoader *)downLoader
{
  if(_downLoader == nil)
  {
      _downLoader = [[LZBAudioDownLoader alloc]init];
      _downLoader.downLoaderDelegate = self;
  }
    return _downLoader;
}

- (NSMutableArray *)downLoadedDataRequests
{
  if(!_downLoadedDataRequests)
  {
      _downLoadedDataRequests = [NSMutableArray array];
  }
    return _downLoadedDataRequests;
}
@end
