//
//  YQDRecorer.m
//
//  Created by Neptune on 2018/9/14.
//  Copyright © 2018年 spud. All rights reserved.
//
#define NTWeakSelf __weak typeof(self) weakSelf = self
#import "NPRecorder.h"

@interface NPRecorder()
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, copy) NSString *basePath;

/**
   tag if prepare to capture sampleBuffer ，only once
 */
@property (nonatomic, assign) BOOL startSession;

/*
  stop or start tag
 */

@property (nonatomic, assign) BOOL isRecording;
@end

@implementation NPRecorder

- (void)startRecordingFileName:(NSString *)fileName startHander:(void(^)(void))handler {
    
    if (!self.isRecording) {
        NSString *basePath = [self buildBasePath];
        
        NSString *final = [NSString stringWithFormat:@"%@%@.mp4",basePath,fileName];
        
        self.currentVideoURL = [NSURL fileURLWithPath:final];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:final]) {
            NSLog(@"该文件已经存在");
            
            //用removeitematurl
//            NSURL *fileUrl = [NSURL URLWithString:final];
            NSURL *fileUrl = [NSURL fileURLWithPath:final];
            [[NSFileManager defaultManager]  removeItemAtURL:fileUrl error:nil];

            
//            //删除某目录下的地址
//          NSArray *subfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:nil];
//            for (NSString* object in subfiles) {
//                //有时不能删干净
//                [[NSFileManager defaultManager]  removeItemAtPath:object error:nil];
//            }
            
//            return;
        }
        
        self.assetWriter = [AVAssetWriter assetWriterWithURL:self.currentVideoURL fileType:AVFileTypeMPEG4 error:nil]; //AVFileTypeQuickTimeMovie  AVFileTypeMPEG4
        
        
        self.assetWriter.movieTimeScale = 60;
        
//        NSNumber * videoWidth = [NSNumber numberWithFloat:floor([UIScreen mainScreen].bounds.size.width / 16) * 16];
//        NSNumber * videoHeight = [NSNumber numberWithFloat:floor([UIScreen mainScreen].bounds.size.height / 16) * 16];
        
        NSNumber * videoWidth = [NSNumber numberWithFloat:floor([UIScreen mainScreen].bounds.size.width)];
        NSNumber * videoHeight = [NSNumber numberWithFloat:floor([UIScreen mainScreen].bounds.size.height)];
                                                                 
        NSDictionary *videoSettings = @{AVVideoCodecKey:AVVideoCodecTypeH264,
                                        AVVideoWidthKey: videoWidth,
                                        AVVideoHeightKey: videoHeight};
        
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        self.videoInput.mediaTimeScale = 60;
        
        if ([self.assetWriter canAddInput:self.videoInput]) {
            [self.assetWriter addInput:self.videoInput];
        }
        
        AudioChannelLayout channellayout;
        channellayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_5_0_D;
        
//        @{AVNumberOfChannelsKey:@"1",
//          AVFormatIDKey:@"1633772320",
//          AVSampleRateKey:@"44100",
//
//          //    AVEncoderBitRateKey:@"64000"
//          };

        
        NSMutableDictionary *audioSettings = [NSMutableDictionary dictionary];
        [audioSettings setObject:[NSNumber numberWithInt: 1633772320] forKey: AVFormatIDKey];
        [audioSettings setObject:[NSNumber numberWithFloat:44100] forKey: AVSampleRateKey];
        [audioSettings setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        [audioSettings setObject:[NSNumber numberWithInt:64000] forKey:AVEncoderBitRateKey];
//        [audioSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        self.audioInput.expectsMediaDataInRealTime = true;
        
        if ([self.assetWriter canAddInput:self.audioInput]){
            [self.assetWriter addInput:self.audioInput];
        }
        
//        BOOL success = [_assetWriter startWriting];
//
//        if ( ! success ) {
//            NSLog(@"%@",_assetWriter.error);
//        }
        
        RPScreenRecorder * rpRecoder = [RPScreenRecorder sharedRecorder];
        
        [rpRecoder setMicrophoneEnabled:YES];
        
        NTWeakSelf;
        
        [rpRecoder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            
            if (weakSelf.isRecording == NO) {
                
                weakSelf.isRecording = YES;
                
                //开始
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (handler) {
//
//                        handler();
//                    }
//
//                });
            }
            
//            dispatch_async(dispatch_get_main_queue(), ^{
            
                if (CMSampleBufferDataIsReady(sampleBuffer)) {
                    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
                    
                        if (!self.startSession) {
                            self.startSession = YES;
                            [self.assetWriter startWriting];
                            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                        }
                     }
                }

//            });
            
            if (self.assetWriter.status == AVAssetWriterStatusFailed) {
                NSLog(@"%@",self.assetWriter.error);
                return;
            }
            
            if (bufferType == RPSampleBufferTypeVideo) {
                
                if(self.assetWriter.status == AVAssetWriterStatusWriting){
                    
                    if (self.videoInput.isReadyForMoreMediaData) {
                        [self.videoInput appendSampleBuffer:sampleBuffer];
                    }
                }
            }

            if (bufferType == RPSampleBufferTypeAudioMic) {
 
                if(self.assetWriter.status == AVAssetWriterStatusWriting){
                    
                    if (self.audioInput.isReadyForMoreMediaData) {
                        [self.audioInput appendSampleBuffer:sampleBuffer];
                    }
                }

            }
            
        } completionHandler:^(NSError * _Nullable error) {
            
            if (!error) {
                NSLog(@"Recording started successfully BUT FAILED TO RECORD.");
            }else{
                NSLog(@"Recording started error %@",error);
            }
            
        }];
    }
}

- (void)stopComletion:(void(^)(NSArray* arr))hander{
 
    NTWeakSelf;
    self.isRecording = NO;
    
    [RPScreenRecorder.sharedRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
        
        weakSelf.isRecording = NO;
        weakSelf.startSession = NO;
        
        [self.videoInput markAsFinished];
        
        [self.audioInput markAsFinished];
        
        [weakSelf.assetWriter finishWritingWithCompletionHandler:^{
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSURL *documentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:(NSUserDomainMask)] firstObject];
            
            NSURL *replayPathUrl = [documentsDirectory URLByAppendingPathComponent:@"/Replays"];
            
            NSArray*contentArr = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:replayPathUrl includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants)  error:nil];
            
            NSLog(@"%@",contentArr);
            
            
            //finished，recall
            if (hander) {
                hander(contentArr);
            }
 
        }];
    }];
}

- (NSString *)buildBasePath{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *filePathNearParent = [NSString stringWithFormat:@"%@/Replays/",documentDirectory];
     NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePathNearParent]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePathNearParent withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!error) {
        
        NSLog(@"%@",[error description]);
    }
    self.basePath = filePathNearParent;
    return filePathNearParent;
}

@end
