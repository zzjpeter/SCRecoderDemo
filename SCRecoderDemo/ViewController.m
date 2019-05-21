//
//  ViewController.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/17.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "ViewController.h"
#import "ScreenCapture.h"
#import "ZHeader.h"

@interface ViewController ()<ScreenCaptureDelegate>

//videorecord
@property (nonatomic,strong) ScreenCapture *videoRecord;
@property (nonatomic,copy) NSString *videoPath;
@property (nonatomic,strong) UIView *screenCaptureView;



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


@end
