//
//  AVUtil.h
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVUtil : NSObject

+ (void)createCacheDirectory;
+ (void)clearCacheDirectory;

#pragma mark -合并指定的index 的视频轨 和 音频轨 to .mp4文件
+ (void)mergerWithOutputPath:(NSString *)outputPath
                   thumbnail:(NSString *)thumbnail
               withVideoType:(NSInteger)theVideoType
      withVideoAndAudioIndex:(NSInteger)videoAndAudioIndex
                      sucess:(void(^)(void))scallback
                      failer:(void(^)(NSError * error))fcallback;

#pragma mark -合并指定的index 的视频轨 和 视频轨 to 文件
+ (void)mergerWithOutputPathLast:(NSString *)outputPath
                   withVideoType:(NSInteger)theVideoType
          withVideoAndAudioIndex:(NSInteger)videoAndAudioIndex
                          sucess:(void(^)(void))scallback
                          failer:(void(^)(NSError * error))fcallback;

@end

NS_ASSUME_NONNULL_END
