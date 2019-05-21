//
//  ViewController.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/17.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "ViewController.h"
#import "ScreenCapture.h"
#import "IMRecordToolKit.h"
#import "RecordAudio.h"
#import "ZHeader.h"

@interface ViewController ()<ScreenCaptureDelegate>

//videorecord
@property (nonatomic,strong) ScreenCapture *videoRecord;
@property (nonatomic,copy) NSString *videoPath;
@property (nonatomic,strong) UIView *screenCaptureView;

//audiorecord
@property (nonatomic,strong) IMRecordToolKit *audioRecord;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (IBAction)videoRecordAction:(id)sender {
    [self testVideoRecord];
}
- (IBAction)audioRecordAction:(id)sender {
    [self testAudioRecord];
}
- (IBAction)stopAudioRecordAction:(id)sender {
    [_audioRecord finished];
}

#pragma mark -test capture 录屏测试
- (void)testVideoRecord
{
    NSString *vPath = pathcwf(@"videorecord.mov");
    NSLog(@"vPath:%@",vPath);
    [self addRecordVideo:vPath];
}

-(void)addRecordVideo:(NSString*)videoPath {
    
    if (_videoRecord != nil) {
        _videoRecord = nil;
    }
    
    self.videoPath = videoPath;
    [self.videoRecord start];
    
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                NSLog(@"audio recording not permitted.");
            }
        }];
    }
}

- (ScreenCapture *)videoRecord
{
    if (!_videoRecord) {
        ScreenCapture *screenCapture = [[ScreenCapture alloc] initWithVideoPath:self.videoPath];
        screenCapture.delegate = self;
        screenCapture.captureView = self.screenCaptureView;
        _videoRecord = screenCapture;
    }
    return _videoRecord;
}

- (UIView *)screenCaptureView
{
    if (!_screenCaptureView) {
        UIView *screenCaptureView = [UIApplication sharedApplication].keyWindow;
        _screenCaptureView = screenCaptureView;
    }
    return _screenCaptureView;
}

#pragma mark ScreenCaptureDelegate
- (void)screenCaptureDidProgress:(float)progress
{
    NSLog(@"%@##%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

- (void)screenCaptureDidFinsished:(BOOL)pausedManually
{
    NSLog(@"%@##%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

#pragma mark -test audiorecord 录音测试
- (void)testAudioRecord
{
    [self addAudioVideo:nil];
}

-(void)addAudioVideo:(NSString*)audioPath {
    
    if (_audioRecord != nil) {
        _audioRecord = nil;
    }
    [self.audioRecord start];
}

- (IMRecordToolKit *)audioRecord
{
    if (!_audioRecord) {
        IMRecordToolKit *audioRecord = [[IMRecordToolKit alloc] init];
        _audioRecord = audioRecord;
    }
    return _audioRecord;
}

#pragma mark IMRecordToolkitDelegate

- (void)IMRecordToolkitDidFinished:(id)sender duration:(CGFloat)duration
{
    NSLog(@"%@##%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}
- (void)IMRecordToolkitDidError:(NSError *_Nullable)error
{
    NSLog(@"%@##%@",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
}

@end
