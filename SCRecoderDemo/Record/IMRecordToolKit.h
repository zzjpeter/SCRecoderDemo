//
//  IMRecordToolKit.h
//  SCRecoderDemo
//
//  Created by 朱志佳 on 2019/5/20.
//  Copyright © 2019 朱志佳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IMRecordToolkitDelegate <NSObject>

- (void)IMRecordToolkitDidFinished:(id)sender duration:(CGFloat)duration;
- (void)IMRecordToolkitDidError:(NSError *_Nullable)error;

@end

/**
 *  录音工具
 */
@interface IMRecordToolKit : NSObject

@property (nonatomic, assign) BOOL runing;
/**
 *  参数配置
 */
@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) NSString *outputString;
/**
 *  委托
 */
@property (nonatomic, weak) id<IMRecordToolkitDelegate> delegate;
/**
 
 * @brief 判断是否插入了耳机
 */
+ (BOOL)isHeadphone;
/**
 * @brief 初始化音频会话
 */
+ (void)setupAudioSession;
/**
 *  开始录制
 */
- (void)start;
- (void)startWithPath:(NSString *)audioPath;

/**
 *  结束录制
 */
- (void)finished;

@end

NS_ASSUME_NONNULL_END
