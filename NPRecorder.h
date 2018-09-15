//
//  YQDRecorer.h
//
//  Created by Neptune on 2018/9/14.
//  Copyright © 2018年 spud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <ReplayKit/ReplayKit.h>

@interface NPRecorder : NSObject

@property (nonatomic, strong) NSURL *currentVideoURL;

- (void)startRecordingFileName:(NSString *)fileName startHander:(void(^)(void))handler;
- (void)stopComletion:(void(^)(NSArray* arr))hander;
@end
