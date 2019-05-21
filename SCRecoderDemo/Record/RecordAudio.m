//
//  RecordAudio.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "RecordAudio.h"
#import "ZHeader.h"

@interface RecordAudio ()<AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation RecordAudio

- (instancetype)init
{
    self = [super init];
    if (self) {
        [RecordAudio setupAudioSession];
        NSDictionary *dict = @{AVSampleRateKey : @(16000),
                               AVFormatIDKey : @(kAudioFormatLinearPCM),
                               AVNumberOfChannelsKey : @(1),
                               AVLinearPCMBitDepthKey : @(16),
                               AVLinearPCMIsBigEndianKey : @(NO),
                               AVLinearPCMIsFloatKey : @(NO)
                               };
        self.settings = [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    return self;
}

- (void)start
{
    NSString *audioPath = [CacheHelper pathForCommonFile:@"audio" withType:0];
    [self startWithPath:audioPath];
}

- (void)startWithPath:(NSString *)audioPath
{
    [self startWithPath:audioPath timeInterval:0];
}

- (void)startWithPath:(NSString *)audioPath timeInterval:(NSTimeInterval)timeInterval
{
    if (_recorder.isRecording) {
        NSLog(@"录音进行中....");
        return;
    }
    if (IsEmpty(audioPath)) {
        NSLog(@"文件临时存储位置未设置");
        return;
    }
    self.tempString = audioPath;
    NSError *error = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:audioPath] settings:self.settings error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    _recorder.delegate = self;
    if ([_recorder prepareToRecord]) {
        if (!timeInterval) {
            [_recorder record];
        }else
        {
            [_recorder recordAtTime:timeInterval];
        }
    }
}

- (void)pause
{
    if ([_recorder isRecording]) {
        [_recorder pause];
    }
}

- (void)finished
{
    [_recorder stop];
    _recorder = nil;
}

-(void)dealloc
{
    [self finished];
    _recorder = nil;
}

#pragma mark private
#pragma mark 必须在开始录制之前调用来设置，否则音频录制无效
+ (void)setupAudioSession
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"error:%@",error);
    }
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"error:%@",error);
    }
    if (![self isHeadphone]) {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (error) {
            NSLog(@"error:%@",error);
        }
    }
}

//判断是否插入了耳机
+ (BOOL)isHeadphone
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

#pragma mark AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"error:%@", error);
    }
    if (!flag) {
        if ([self.delegate respondsToSelector:@selector(RecordToolkitDidError:)]) {
            [self.delegate RecordToolkitDidError:nil];
        }
        return;
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(RecordToolkitDidError:)]) {
        [self.delegate RecordToolkitDidError:error];
    }
}


@end
