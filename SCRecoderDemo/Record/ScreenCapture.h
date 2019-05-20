//
//  ScreenCapture.h
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/17.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <mach/mach_time.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScreenCaptureDelegate <NSObject>

- (void)screenCaptureDidProgress:(float)progress;
- (void)screenCaptureDidFinsished:(BOOL)pausedManually;

@end

@interface ScreenCapture : NSObject
{
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_wVideoAdaptor;
    u_int64_t _startAtNumber;
    BOOL _ready;
    BOOL _recording;
    NSDictionary *_videoSettings;
    NSString *_cacheVideoPath;
}

@property (nonatomic, strong) UIView *captureView;
@property (nonatomic, assign) CGFloat videoWidth;
@property (nonatomic, assign) CGFloat videoHeight;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) NSInteger frameRate;
@property (nonatomic, assign, readonly) double durationCounter;//有效录频时长 单位s
@property (nonatomic, assign) BOOL isRecordFile;

@property (nonatomic, weak) id<ScreenCaptureDelegate> delegate;

-(instancetype)initWithVideoPath:(NSString*)videoPath;
- (void)start;
- (void)pause;
- (void)finishedRecord:(BOOL)pausedManually;

@end

NS_ASSUME_NONNULL_END
