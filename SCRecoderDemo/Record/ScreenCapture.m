//
//  ScreenCapture.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/17.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "ScreenCapture.h"
#import "ZHeader.h"

@interface ScreenCapture ()

@property (nonatomic,strong) NSMutableArray * userImageArray;

@property (nonatomic,strong) NSTimer * screenTimer;

@property (nonatomic,strong) NSOperationQueue * operationQueue;

@property (nonatomic,strong) NSBlockOperation * blockOperation;

@end

@implementation ScreenCapture

- (instancetype)init
{
    self = [super init];
    if (self) {
        //for scaling
        self.videoWidth  = [UIScreen mainScreen].bounds.size.width;
        self.videoHeight = [UIScreen mainScreen].bounds.size.height;
        self.frameRate   = 5;
        self.duration    = 60;
        _cacheVideoPath = pathcwf(@"player/video.mov");
        unlink([_cacheVideoPath UTF8String]);
        
        [self prepareToRecord];
    }
    return self;
}

-(instancetype)initWithVideoPath:(NSString*)videoPath {
    self = [super init];
    if (self) {
        //*2 for scaling
        self.videoWidth  = [UIScreen mainScreen].bounds.size.width;
        self.videoHeight = [UIScreen mainScreen].bounds.size.height;
        self.frameRate   = 15;
        self.duration    = 5 * 60;
        _cacheVideoPath = videoPath;
        unlink([_cacheVideoPath UTF8String]);
        [self prepareToRecord];
    }
    return self;
}

- (BOOL)prepareToRecord
{
    if (!_ready) {
        
        NSError *error = nil;
        AVAssetWriter *writer = nil;
        AVAssetWriterInput *input = nil;
        NSURL *url = [NSURL fileURLWithPath:_cacheVideoPath];
        writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
        if (error) {
            NSLog(@"%@", error);
            NSLog(@"%@", [NSString stringWithFormat:@"%@:%@",@"录屏",@"录屏准备失败"]);
            return NO;
        }
        NSInteger numPixels = self.videoWidth * self.videoHeight;
        CGFloat bitsPerPiex = 6.0;
        NSInteger bitsPerSecond = numPixels * bitsPerPiex;
        
        NSDictionary *comperssion  = @{
                                       AVVideoAverageBitRateKey : @(bitsPerSecond),
                                       AVVideoExpectedSourceFrameRateKey : @(10),
                                       AVVideoMaxKeyFrameIntervalKey : @(10),
                                       AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel
                                       };
        NSDictionary *videoSettings = @{
                                        AVVideoCodecKey : AVVideoCodecH264,
                                        AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                        AVVideoWidthKey : @(self.videoWidth),
                                        AVVideoHeightKey : @(self.videoHeight),
                                        AVVideoCompressionPropertiesKey : comperssion
                                        };
        input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        input.expectsMediaDataInRealTime = YES;
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey, nil];
        
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:attributes];
        
        if ([writer canAddInput:input]) {
            [writer addInput:input];
        }else {
            NSLog(@"%@",[NSString stringWithFormat:@"%@:%@",@"录屏",@"writerInput失败"]);
        }
        _assetWriter = writer;
        _assetWriterInput = input;
        _wVideoAdaptor = adaptor;
        _ready = YES;
        _videoSettings = videoSettings;
        [_assetWriter startWriting];
        [_assetWriter startSessionAtSourceTime:kCMTimeZero];
    }
    
    return YES;
}

- (void)start {
    self.isRecordFile = YES;
    
    if(_ready && !_recording) {
        _recording = YES;
        _startAtNumber = mach_absolute_time();
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadHandler) object:nil];
        [thread start];
    }
}

- (void)pause {
    if (_recording) {
        _recording = NO;
        _durationCounter += [self getElapsed];
    }
}

- (void)finishedRecord:(BOOL)pausedManually
{
    if (_recording) {
        //    NSLog(@"Call finishedRecord.1");
        [self pause];
        [self releaseTimer:_screenTimer];
        [_assetWriterInput markAsFinished];
        CMTime elapsed = CMTimeMake((int)([self getElapsed] + _durationCounter) * 1000, 1000);
        [_assetWriter endSessionAtSourceTime:elapsed];
        @weakify(self)
        [_assetWriter finishWritingWithCompletionHandler:^{
            @strongify(self)
            self->_assetWriterInput = nil;
            self->_assetWriter = nil;
            self->_wVideoAdaptor = nil;
            if ([self.delegate respondsToSelector:@selector(screenCaptureDidFinsished:)]) {
                [self.delegate screenCaptureDidFinsished:pausedManually];
            }
        }];
    }
}

#pragma mark private
- (void)threadHandler {
    if (@available(iOS 10.0, *)) {
        [self screenTimer];
    }else {
        // Fallback on earlier versions
    }
}

- (NSTimer *)screenTimer {
    if(!_screenTimer){
        @weakify(self)
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1/self.frameRate block:^(NSTimer * _Nonnull timer) {
            @strongify(self)
            if (self->_recording == YES) {
                [self videoWriterTimerHandler:nil];
            }
        } repeats:YES];
        _screenTimer = timer;
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
    return _screenTimer;
}

- (void)releaseTimer:(NSTimer *)timer{
    [timer invalidate];
    timer = nil;
}

- (double)getElapsed
{
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    uint64_t timeInterval = mach_absolute_time() - _startAtNumber;
    
    timeInterval *= info.numer;
    timeInterval /= info.denom;
    
    //纳秒转换为秒
    float duration = (timeInterval * 1.0f) / 1000000000;
    
    return duration;
}

- (void)videoWriterTimerHandler:(NSTimer *)timer{
    if (_recording) {
        @autoreleasepool {
            CMTime elapsed = CMTimeMake((int)(([self getElapsed] + _durationCounter)*1000), 1000);
            UIImage *image = [self imageFromView:self.captureView];
            if (image) {
                CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage];
                if ([_assetWriterInput isReadyForMoreMediaData] && _recording) {
                    if (_wVideoAdaptor) {
                        @try {
                            if (![_wVideoAdaptor appendPixelBuffer:buffer withPresentationTime:elapsed]) {
                                NSLog(@"%@",[NSString stringWithFormat:@"%@:%@",@"录屏",@"插针Cache失败"]);
                                NSLog(@"FAIL");
                                [self finishedRecord:NO];
                                CFRelease(buffer);
                                return;
                            }
                        } @catch (NSException *exception) {
                            NSLog(@"%@",[NSString stringWithFormat:@"%@:%@",@"录屏",@"插针Cache"]);
                            NSError *error = [_assetWriter error];
                            NSString * errStr = [NSString stringWithFormat:@"failed to append sbuf: %@",error];
                            NSLog(@"%@",[NSString stringWithFormat:@"%@:%@",@"录屏",errStr]);
                            [self finishedRecord:NO];
                            CFRelease(buffer);
                            return;
                        } @finally {
                            
                        }
                        
                        if (_recording == NO) {
                            _durationCounter += [self getElapsed];
                        }
                        CGFloat progress = (CMTimeGetSeconds(elapsed)/self.duration);
                        if (progress >= 1.0f) {
                            [self finishedRecord:NO];
                            CFRelease(buffer);
                            return;
                        }else {
                            if ([self.delegate respondsToSelector:@selector(screenCaptureDidProgress:)]) {
                                [self.delegate screenCaptureDidProgress:(CMTimeGetSeconds(elapsed) / self.duration)];
                            }
                        }
                    }
                    CFRelease(buffer);
                }
            }
        }
    }
}

static OSType KVideoPixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
- (CVPixelBufferRef)yuvPixelBufferWithData:(NSData *)dataFrame
                          presentationTime:(CMTime)presentationTime
                                     width:(size_t)w
                                    heigth:(size_t)h
{
    unsigned char *buffer = (unsigned char*)dataFrame.bytes;
    CVPixelBufferRef getCroppedPixelBuffer = [self copyDataFromBuffer:buffer toYUVPixelBufferWithWidth:w Height:h];
    return getCroppedPixelBuffer;
}

-(CVPixelBufferRef)copyDataFromBuffer:(const unsigned char*)buffer toYUVPixelBufferWithWidth:(size_t)w Height:(size_t)h
{
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionary],kCVPixelBufferIOSurfaceOpenGLESFBOCompatibilityKey, nil];
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(NULL, w, h, KVideoPixelFormatType, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    const unsigned char *src = buffer;
    unsigned char* dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    for (unsigned int rIdx = 0; rIdx < h; ++rIdx, dst += d, src += w) {
        memcpy(dst, src, w);
    }
    
    d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    CVPixelBufferRef pxbuffer = NULL;
    CFDictionaryRef option = (__bridge CFDictionaryRef)_videoSettings;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          self.videoWidth,
                                          self.videoHeight,
                                          kCVPixelFormatType_32ARGB,
                                          option,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    int bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst;
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 self.videoWidth,
                                                 self.videoHeight,
                                                 8,
                                                 4 * self.videoWidth,
                                                 rgbColorSpace,
                                                 bitmapInfo);
    NSParameterAssert(context);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, self.videoWidth, self.videoHeight));
    CGContextDrawImage(context, CGRectMake(0, 0, self.videoWidth, self.videoHeight), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

#pragma mark 截屏
- (UIImage *)imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height), NO, [UIScreen mainScreen].scale);
    @try {
        [view drawViewHierarchyInRect:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) afterScreenUpdates:NO];
    } @catch (NSException *exception) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColorFromRGB(0xFFFFFF) CGColor]);
        CGContextFillRect(context, [UIScreen mainScreen].bounds);
        NSLog(@"%@",[NSString stringWithFormat:@"%@:%@",@"录屏",@"截屏闪退Cache"]) ;
    } @finally {
        
    }
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
