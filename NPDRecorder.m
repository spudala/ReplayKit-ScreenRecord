//
//  YQDRecorer.m
//
//  Created by Neptune on 2018/9/14.
//  Copyright © 2018年 spud. All rights reserved.
//
#define NTWeakSelf __weak typeof(self) weakSelf = self
#import "NPRecorder.h"

@interface NPRecorder(){
    //创建一个串行队列  以供写入
    //    dispatch_queue_t  _writingQueue;
}
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, copy) NSString *basePath;

/**
 tag if prepare to capture video sampleBuffer ，only once
 */
@property (nonatomic, assign) BOOL videoStartSession;
/**
 tag if prepare to capture audio sampleBuffer ，only once
 */

@property (nonatomic, assign) BOOL micAudioStartSession;

/*
 stop or start tag
 */

@property (nonatomic, assign) BOOL isRecordingNow;

@end

@implementation NPRecorder

- (instancetype)init {
    if (self = [super init]) {
        
        //        _writingQueue = dispatch_queue_create( "com.yqd.movierecorder.writing", DISPATCH_QUEUE_SERIAL );
    }
    
    return self;
}

- (void)startRecordingFileName:(NSString *)fileName startHander:(void(^)(void))handler {
    
    if (!self.isRecordingNow) {
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
        //        AVVideoCodecTypeHEVC  AVVideoCodecTypeH264
        NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecTypeH264,
                                        AVVideoWidthKey: videoWidth,
                                        AVVideoHeightKey: videoHeight};
        
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        self.videoInput.mediaTimeScale = 60;
        
        self.videoInput.expectsMediaDataInRealTime = true;
        
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
        
        //音频小bug --- 这里会录音
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
        [AVAudioSession.sharedInstance setActive:YES error:nil];
        
        
        
        if ([self.assetWriter canAddInput:self.audioInput]){
            [self.assetWriter addInput:self.audioInput];
        }
        
        BOOL success = [_assetWriter startWriting];
        
        if ( ! success ) {
            NSLog(@"%@",_assetWriter.error);
        }
        
        RPScreenRecorder * rpRecoder = [RPScreenRecorder sharedRecorder];
        
        [rpRecoder setMicrophoneEnabled:YES];
        
        NTWeakSelf;
        
        //        if (weakSelf.isRecordingNow == NO) {
        //
        //            weakSelf.isRecordingNow = YES;
        //
        //            if (handler) {
        //
        //                handler();
        //            }
        //
        //        }
        
        [rpRecoder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            
            /*----外层多一些控制---*/
            if (!CMSampleBufferDataIsReady(sampleBuffer)) return;
            
            if (weakSelf.assetWriter.status != AVAssetWriterStatusWriting) return;
            /*----外层多一些控制---*/
            
            if (weakSelf.isRecordingNow == NO) {
                
                weakSelf.isRecordingNow = YES;
                
                if (handler) {
                    
                    handler();
                }
                
            }
            
            
            switch (bufferType) {
                case RPSampleBufferTypeVideo:
                    if (!weakSelf.videoStartSession) {
                        weakSelf.videoStartSession = YES;
                        [weakSelf.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    }
                    if (weakSelf.videoInput.isReadyForMoreMediaData) {
                        [weakSelf.videoInput appendSampleBuffer:sampleBuffer];
                    }
                    break;
                case RPSampleBufferTypeAudioMic:
                    if (!weakSelf.micAudioStartSession) {
                        weakSelf.micAudioStartSession = YES;
                        [weakSelf.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    }
                    if (weakSelf.audioInput.isReadyForMoreMediaData) {
                        [weakSelf.audioInput appendSampleBuffer:sampleBuffer];
                    }
                    break;
                default:
                    break;
            }
            
            
        } completionHandler:^(NSError * _Nullable error) {
            
            if (!error) {
                NSLog(@"Recording started successfully .");
            }else{
                NSLog(@"Recording started error %@",error);
            }
            
        }];
    }
}

- (void)stopComletion:(void(^)(NSArray* arr))hander{
    
    NTWeakSelf;
    
    self.isRecordingNow = NO;
    
    [RPScreenRecorder.sharedRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
        
        weakSelf.isRecordingNow = NO;
        weakSelf.videoStartSession = NO;
        weakSelf.micAudioStartSession = NO;
        
        [weakSelf.videoInput markAsFinished];
        
        [weakSelf.audioInput markAsFinished];
        
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

#pragma mark - 获取存储地址目录
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
