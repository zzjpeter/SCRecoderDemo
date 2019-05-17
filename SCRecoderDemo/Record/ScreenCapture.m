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
    }
    return self;
}

@end
