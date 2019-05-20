//
//  AVUtil.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "AVUtil.h"
#import <AVFoundation/AVFoundation.h>
#import "ZHeader.h"

@implementation AVUtil

+ (void)createCacheDirectory
{
    NSString * path = pathcwf(@"player");
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (void)clearCacheDirectory
{
    NSString * path = pathcwf(@"player");
    NSArray  * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString * entry in files) {
        [[NSFileManager defaultManager] removeItemAtPath:entry error:nil];
    }
}

#pragma mark -合并指定的index 的视频轨 和 音频轨 to .mp4文件
+ (void)mergerWithOutputPath:(NSString *)outputPath
                   thumbnail:(NSString *)thumbnail
               withVideoType:(NSInteger)theVideoType
      withVideoAndAudioIndex:(NSInteger)videoAndAudioIndex
                      sucess:(void(^)(void))scallback
                      failer:(void(^)(NSError * error))fcallback
{
    //叠加的视频
    NSString * videoPath = [NSString stringWithFormat:@"copyvideo_%ld.mov",(long)videoAndAudioIndex];
    NSString *vPath = [[CacheHelper pathForCommonFile:@"video" withType:0] stringByAppendingPathComponent:videoPath];
    
    NSString *audioPath = [NSString stringWithFormat:@"copyaudio_%ld.aac",(long)videoAndAudioIndex];
    NSString *aPath = [[CacheHelper pathForCommonFile:@"audio" withType:0] stringByAppendingPathComponent:audioPath];
    
    if (![CacheHelper checkfile:aPath]) {
        NSLog(@"audio file not exists");
        return;
    }
    if (![CacheHelper checkfile:vPath]) {
        NSLog(@"video file not exists");
        return;
    }
    
    AVURLAsset *vasset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:vPath] options:nil];
    AVURLAsset *aasset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:aPath] options:nil];
    //设置音轨
    AVAssetTrack *videoAssetTrack = nil;
    AVAssetTrack *audioAssetTrack = nil;
    if ([vasset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        videoAssetTrack = [vasset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    }
    if ([aasset tracksWithMediaType:AVMediaTypeAudio].count > 0) {
        audioAssetTrack = [aasset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    }
    
    //视频帧图片
    UIImage *image = [self imageFromVideoAsset:vasset videoAssetTrack:videoAssetTrack];
    if (image) {
        NSData *data = UIImageJPEGRepresentation(image, 0.6);
        [data writeToFile:thumbnail atomically:YES];
    }
    
    //音频和视频的合并
    AVMutableComposition      * composition;
    AVMutableCompositionTrack * videoCompositionTrack;
    AVMutableCompositionTrack * audioCompositionTrack;
    composition = [AVMutableComposition composition];
    
    videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error = nil;
    [videoCompositionTrack insertTimeRange:videoAssetTrack.timeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }
    [audioCompositionTrack insertTimeRange:audioAssetTrack.timeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }
    
    //创建一个输出
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    exportSession.outputFileType =  AVFileTypeMPEG4;
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.shouldOptimizeForNetworkUse =  YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        //clear up the temp space
        unlink([aPath UTF8String]);
        unlink([vPath UTF8String]);
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            scallback();
        } else {
            fcallback(exportSession.error);
        }
    }];
}

#pragma mark 获取视频轨中的一帧图片
+ (UIImage *)imageFromVideoAsset:(AVAsset *)videoAsset videoAssetTrack:(AVAssetTrack *)videoAssetTrack
{
    //获取视频中每一帧图片
    UIImage *image = nil;
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:videoAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    NSError *error = nil;
    //时间是最后的时候的时间
    CGImageRef img = [generator copyCGImageAtTime:videoAssetTrack.timeRange.duration actualTime:nil error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }else {
        image = [UIImage imageWithCGImage:img];
    }
    CGImageRelease(img);
    return image;
}

+ (void)mergerWithOutputPathLast:(NSString *)outputPath
                   withVideoType:(NSInteger)theVideoType
          withVideoAndAudioIndex:(NSInteger)videoAndAudioIndex
                          sucess:(void(^)(void))scallback
                          failer:(void(^)(NSError * error))fcallback
{
    NSString * videoPath = [NSString stringWithFormat:@"copyvideo_%ld.mov",(long)videoAndAudioIndex];
    NSString *vPath = [[CacheHelper pathForCommonFile:@"video" withType:0] stringByAppendingPathComponent:videoPath];
    
    NSString * gpuVideoPath = [NSString stringWithFormat:@"copyvideoGPU_%ld.mov",(long)videoAndAudioIndex];
    NSString *gpuPath = [[CacheHelper pathForCommonFile:@"video" withType:0] stringByAppendingPathComponent:gpuVideoPath];
    

    //[self cutVideoWithInputPath:gpuPath WithOutputPath:outputPath WithFinished:^{
        //叠加视频
        [self insertPictureWith:vPath withPic2:gpuPath outPath:outputPath sucess:^{
            scallback();
        } failer:fcallback];
    //}];
}

#pragma mark -合并指定的index 的视频轨 和 视频轨 to 文件
+ (void)insertPictureWith:(NSString *)videoPath withPic2:(NSString *)videoGPUPath outPath:(NSString *)outPath sucess:(void(^)(void))scallback failer:(void(^)(NSError * error))fcallback
{
    // 1. 获取视频资源AVURLAsset
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];// 本地文件
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    CGSize videoPlyerSize = videoAsset.naturalSize;
    
    NSURL * videoGPUURL = [NSURL fileURLWithPath:videoGPUPath];
    AVAsset * videoGPUAsset = [AVURLAsset URLAssetWithURL:videoGPUURL options:nil];
    
    if (!videoAsset) {
        NSLog(@"videoAsset not exist");
        return;
    }
    CMTime durationTime = videoAsset.duration;//视频的时长
    // 2. 创建自定义合成对象AVMutableComposition
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [self videoCompositionTrack:mixComposition andAssert:videoAsset atTime:kCMTimeZero];//第一视频轨
    AVMutableCompositionTrack *videoTrack1 = [self videoCompositionTrack:mixComposition andAssert:videoGPUAsset atTime:kCMTimeZero];//第二视频轨
    videoPlyerSize = videoTrack.naturalSize;
    
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction1 = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack1];
    [videolayerInstruction1 setTransform:CGAffineTransformMake(0.9, 0.0, 0.0, 0.9, 50, 50) atTime:kCMTimeZero];
    
    // 5. 创建视频组件的指令AVMutableVideoCompositionInstruction，这个类主要用于管理应用层的指令。
    AVMutableVideoCompositionInstruction *mainCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainCompositionIns.timeRange = CMTimeRangeMake(kCMTimeZero, durationTime);// 设置视频轨道的时间范围
    mainCompositionIns.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction, videolayerInstruction1, nil];
    
   // 6. 创建视频组件AVMutableVideoComposition,这个类是处理视频中要编辑的东西。可以设定所需视频的大小、规模以及帧的持续时间。以及管理并设置视频组件的指令
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.renderSize = CGSizeMake(videoPlyerSize.width, videoPlyerSize.height);
    mainComposition.instructions = [NSArray arrayWithObject:mainCompositionIns];
    mainComposition.frameDuration = CMTimeMake(1, 15); // FPS 帧
    
    // 7. 创建视频导出会话对象AVAssetExportSession,主要是根据videoCompositio去创建一个新的视频，并输出到一个指定的文件路径中去。
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset960x540];
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, durationTime);
    exporter.outputURL = [NSURL fileURLWithPath:outPath];
    exporter.shouldOptimizeForNetworkUse = YES;
    if (mainComposition.renderSize.width != 0 && mainComposition.renderSize.height != 0) {
        exporter.videoComposition = mainComposition;
    }
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        //clear up temp space
        unlink([videoPath UTF8String]);
        unlink([videoGPUPath UTF8String]);
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            scallback();
        }else {
            fcallback(exporter.error);
        }
    }];
}

+ (AVMutableCompositionTrack*)videoCompositionTrack:(AVMutableComposition*)mixComposition andAssert:(AVAsset*)videoAsset atTime:(CMTime)atTime
{
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *videoAssetTracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    if (videoAssetTracks.count == 0) {
        return nil;
    }
    //    视频流集合中的第一个流数据。一般情况，只存在一个视频流和一或多个音频流。
    NSError *error = nil;
    AVAssetTrack *videoAssetTrack = videoAssetTracks.firstObject;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:videoAssetTrack atTime:atTime error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }
    return videoTrack;
}

#pragma mark -编辑指定的index 的视频轨 to 文件
+ (void)cutVideoWithInputPath:(NSString *)inputPath WithOutputPath:(NSString *)outputFielPath WithFinished:(void (^)(void))finished
{
    AVMutableComposition *compostion = [[AVMutableComposition alloc] init];
    CMTime totalDuration = kCMTimeZero;
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:inputPath]];
    AVAssetTrack *videoAssetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    AVMutableCompositionTrack *videoTrack = [compostion addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    totalDuration = CMTimeAdd(totalDuration, asset.duration);
    
    CGSize renderSize = CGSizeMake(0, 0);
    renderSize.width = MAX(renderSize.width, videoAssetTrack.naturalSize.width);
    renderSize.height = MAX(renderSize.height, videoAssetTrack.naturalSize.height);
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    CGFloat rate = renderW / MIN(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
    CGAffineTransform layerTransform = CGAffineTransformMake(videoAssetTrack.preferredTransform.a,
                                                             videoAssetTrack.preferredTransform.b,
                                                             videoAssetTrack.preferredTransform.c,
                                                             videoAssetTrack.preferredTransform.d,
                                                             videoAssetTrack.preferredTransform.tx * rate,
                                                             videoAssetTrack.preferredTransform.tx * rate);
    layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(videoAssetTrack.naturalSize.width - videoTrack.naturalSize.height) / 2.0));
    layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
    [layerInstruction setTransform:layerTransform atTime:kCMTimeZero];
    [layerInstruction setOpacity:0.0 atTime:totalDuration];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    instruction.layerInstructions = @[layerInstruction];
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = @[instruction];
    mainComposition.frameDuration = CMTimeMake(1, 15);
    mainComposition.renderSize = CGSizeMake(renderW, renderW);
    
    // 导出视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:compostion presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = mainComposition;
    exporter.outputURL = [NSURL fileURLWithPath:outputFielPath];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        unlink([inputPath UTF8String]);
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            finished();
        } else {
            finished();
        }
    }];
}

@end
