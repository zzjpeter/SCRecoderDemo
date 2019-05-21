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

@protocol RecordToolkitDelegate <NSObject>

- (void)RecordToolkitDidFinished:(id)sender duration:(CGFloat)duration;
- (void)RecordToolkitDidError:(NSError *_Nullable)error;

@end

@interface RecordAudio : NSObject

@property (nonatomic, weak) id<RecordToolkitDelegate> delegate;
@property (nonatomic,strong) NSMutableDictionary *settings;
@property (nonatomic,copy) NSString *tempString;//临时存储路径

- (void)start;
- (void)startWithPath:(NSString *)audioPath;
- (void)startWithPath:(NSString *)audioPath timeInterval:(NSTimeInterval)timeInterval;
- (void)pause;
- (void)finished;

@end

NS_ASSUME_NONNULL_END
