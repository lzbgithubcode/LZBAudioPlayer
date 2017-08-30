//
//  LZBAudioResourceLoader.h
//  LZBAudioPlayer
//
//  Created by zibin on 2017/7/25.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface LZBAudioResourceLoader : NSObject <AVAssetResourceLoaderDelegate>

/**
 获取请求资源加工后的URL

 @param inputURL inputURL输入URL
 @return 转化后的URL
 */
- (NSURL *)getAudioResourceLoaderSchemeURLWithInPutURL:(NSURL *)inputURL;
@end
