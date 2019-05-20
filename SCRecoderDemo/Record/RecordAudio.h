//
//  RecordAudio.h
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordAudio : NSObject
{
    AVAudioRecorder *_record;
    NSString *_cacheAudioPath;
}

- (id)initWithAudioPath:(NSString *)audioPath;

- (void)start:(NSTimeInterval)timeInterval;
- (void)pause;
- (void)finishedRecord;

@end

NS_ASSUME_NONNULL_END
