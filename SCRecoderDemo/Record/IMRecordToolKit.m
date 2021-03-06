//
//  IMRecordToolKit.m
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import "IMRecordToolKit.h"
#import <AVFoundation/AVFoundation.h>
#import <lame/lame.h>
#import "ZHeader.h"

@interface IMRecordToolKit ()<AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSString *tempString;
/**
 *  参数配置
 */
@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) NSString *outputString;

@end

@implementation IMRecordToolKit

- (instancetype)init
{
    self = [super init];
    if (self) {
        [IMRecordToolKit setupAudioSession];
        NSDictionary *recordSetting = @{AVSampleRateKey : @(44100),//采样率
                                        AVFormatIDKey : @(kAudioFormatLinearPCM),
                                        AVLinearPCMBitDepthKey : @(16),//采样位数 默认 16
                                        AVNumberOfChannelsKey : @(2),//通道的数目
                                        AVEncoderAudioQualityKey : @(AVAudioQualityMax)//音频编码质量
                                        };
        self.settings = [NSMutableDictionary dictionaryWithDictionary:recordSetting];
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
    [self startWithPath:audioPath outputString:[CacheHelper pathForCommonFile:@"audio" withType:SourceTypeVOICE_MP3] timeInterval:0];
}

- (void)startWithPath:(NSString *)audioPath outputString:(NSString *)outputString timeInterval:(NSTimeInterval)timeInterval
{
    if (_recorder.isRecording) {
        NSLog(@"录音进行中....");
        return;
    }
    if (IsEmpty(audioPath)) {
        NSLog(@"文件临时存储位置未设置");
        return;
    }
    if (IsEmpty(outputString)) {
        NSLog(@"文件输出存储位置未设置");
        return;
    }
    NSError *error = nil;
    self.tempString = audioPath;
    self.outputString = outputString;
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
    if (_recorder.isRecording) {
        [_recorder stop];
        _recorder = nil;
    }
}

-(void)dealloc
{
    [self releaseResource];
}

- (void)releaseResource
{
    [self finished];
    _recorder = nil;
    _tempString = nil;
}

#pragma mark private
+ (BOOL)isHeadphone
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}
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
        if ([self.delegate respondsToSelector:@selector(IMRecordToolkitDidError:)]) {
            [self.delegate IMRecordToolkitDidError:nil];
        }
        return;
    }

    @try {
        int read, write;
        FILE *pcm = fopen([self.tempString cStringUsingEncoding:NSASCIIStringEncoding], "rb");//source 被转换的音频文件位置
        if (pcm != NULL) {
            fseek(pcm, 4 * 1024, SEEK_CUR);//skip file header
            FILE *mp3 = fopen([self.outputString cStringUsingEncoding:NSASCIIStringEncoding], "wb");//output 输出生成的Mp3文件位置
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE * 2];
            unsigned char mp3_buffer[MP3_SIZE];

            lame_t lame = lame_init();
            lame_set_num_channels(lame, 2);//设置1为单通道，默认为2双通道
            lame_set_in_samplerate(lame, 44100);//11025.0
            //lame_set_VBR(lame, vbr_default);
            lame_set_brate(lame, 8);
            lame_set_mode(lame, 3);
            lame_set_quality(lame, 7);/* 2=high 5 = medium 7=low 音质*/
            lame_init_params(lame);

            do {
                read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                if (read == 0) {
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                }else{
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }
                fwrite(mp3_buffer, write, 1, mp3);
            } while (read != 0);

            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
//#warning duration必须是mp3文件 才能通过下面的方式正确的获取 音频文件时长
            AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.outputString] options:nil];
            CMTime audioDuration = audioAsset.duration;
            NSLog(@"%f", CMTimeGetSeconds(audioDuration));

            if ([self.delegate respondsToSelector:@selector(IMRecordToolkitDidFinished:duration:)]) {
                [self.delegate IMRecordToolkitDidFinished:self duration:CMTimeGetSeconds(audioDuration)];
            }

            unlink([self.tempString UTF8String]);
        }
    } @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        NSError *error = [[NSError alloc] initWithDomain:@"local" code:-9999 userInfo:@{NSLocalizedDescriptionKey:exception.description}];
        if ([self.delegate respondsToSelector:@selector(IMRecordToolkitDidError:)]) {
            [self.delegate IMRecordToolkitDidError:error];
        }
    } @finally {
        [self releaseResource];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(IMRecordToolkitDidError:)]) {
        [self.delegate IMRecordToolkitDidError:error];
    }
}

@end
