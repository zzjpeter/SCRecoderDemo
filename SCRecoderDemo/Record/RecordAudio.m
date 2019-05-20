//
//  RecordAudio.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "RecordAudio.h"

@implementation RecordAudio

- (instancetype)initWithAudioPath:(NSString *)audioPath
{
    self = [super init];
    if (self) {
        [RecordAudio setupAudioSession];
        NSURL *url = [NSURL fileURLWithPath:audioPath];
        unlink([audioPath UTF8String]);
        NSDictionary *dict = @{AVSampleRateKey : @(16000),
                               AVFormatIDKey : @(kAudioFormatLinearPCM),
                               AVNumberOfChannelsKey : @(1),
                               AVLinearPCMBitDepthKey : @(16),
                               AVLinearPCMIsBigEndianKey : @(NO),
                               AVLinearPCMIsFloatKey : @(NO)
                               };
        NSMutableDictionary *recordSettings = [NSMutableDictionary dictionaryWithDictionary:dict];
        NSError *error = nil;
        _record = [[AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:&error];
        [_record prepareToRecord];
        if (error) {
            NSLog(@"error:%@", error);
        }
    }
    return self;
}

- (void)start:(NSTimeInterval)timeInterval
{
    if ([_record isRecording] == NO) {
        [_record recordAtTime:timeInterval];
    }
}

- (void)pause
{
    if ([_record isRecording]) {
        [_record pause];
    }
}

- (void)finishedRecord
{
    [_record stop];
}

-(void)dealloc
{
    [self finishedRecord];
    _record = nil;
}

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

#pragma mark private
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

@end
