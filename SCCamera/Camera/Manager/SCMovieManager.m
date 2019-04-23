//
//  SCMovieManager.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCMovieManager.h"

static NSString *const SCMovieFileName = @"movie.mov";

@interface SCMovieManager ()
@property (nonatomic, assign) dispatch_queue_t movieQueue;
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic, strong) AVAssetWriter *movieWriter;
@property (nonatomic, strong) AVAssetWriterInput *movieVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *movieAudioInput;

@property (nonatomic, assign, getter=isFirstSample) BOOL firstSample;
@end

@implementation SCMovieManager

#pragma mark - public method
- (instancetype)initWithDispatchQueue:(dispatch_queue_t)dispatchQueue {
    if (self = [super init]) {
        _movieQueue = dispatchQueue;
        _movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"movie.mov"]];
    }
    return self;
}

- (void)startRecordWithVideoSettings:(NSDictionary *)videoSettings
                       audioSettings:(NSDictionary *)audioSettings
                              handle:(void (^ _Nullable)(NSError * _Nonnull))handle {
    dispatch_async(self.movieQueue, ^{
        NSError *error;
        self.movieWriter = [AVAssetWriter assetWriterWithURL:self.movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
        if (!self.movieWriter || error) {
            NSLog(@"movieWriter error.");
            if (handle) handle(error);
            return;
        }
        // 创建视频输入
        self.movieVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        // 针对实时性进行优化
        self.movieVideoInput.expectsMediaDataInRealTime = YES;
        
        // TODO: - 如果应用程序只支持一个方向就需要做图像旋转转换
        // self.movieVideoInput.transform =
        
        if ([self.movieWriter canAddInput:self.movieVideoInput]) {
            [self.movieWriter addInput:self.movieVideoInput];
        } else {
            NSLog(@"Unable to add video input.");
        }
        
        // 创建音频输入
        self.movieAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        // 针对实时性进行优化
        self.movieAudioInput.expectsMediaDataInRealTime = YES;
        if ([self.movieWriter canAddInput:self.movieAudioInput]) {
            [self.movieWriter addInput:self.movieAudioInput];
        } else {
            NSLog(@"Unable to add audio input.");
        }
        
        self.recording = YES;
        self.firstSample = YES;
    });
}

- (void)recordSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.isRecording) {
        return;
    }
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (mediaType == kCMMediaType_Video) {
        // 视频数据处理
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (self.isFirstSample) {
            if ([self.movieWriter startWriting]) {
                [self.movieWriter startSessionAtSourceTime: timestamp];
            } else {
                NSLog(@"Failed to start writing.");
            }
            self.firstSample = NO;
        }
        if (self.movieVideoInput.readyForMoreMediaData) {
            if (![self.movieVideoInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending video sample buffer.");
            }
        }
    } else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        // 音频数据处理(已处理至少一个视频数据)
        if (self.movieAudioInput.readyForMoreMediaData) {
            if (![self.movieAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending audio sample buffer.");
            }
        }
    }
}

- (void)stopRecordWithCompletion:(void (^)(BOOL, NSURL * _Nullable))completion {
    self.recording = NO;
    dispatch_async(self.movieQueue, ^{
        [self.movieWriter finishWritingWithCompletionHandler:^{
            switch (self.movieWriter.status) {
                case AVAssetWriterStatusCompleted:{
                    self.firstSample = YES;
                    NSURL *fileURL = [self.movieWriter outputURL];
                    completion(YES, fileURL);
                    
                    // FIXME: - 测试用保存
                    [self saveMovieToCameraRoll:fileURL authHandle:^(BOOL success, PHAuthorizationStatus status) {
                        NSLog(@"相册添加权限：%d, %ld", success, (long)status);
                    } completion:^(BOOL success, NSError * _Nullable error) {
                        NSLog(@"视频添加结果：%d, %@", success, error);
                    }];
                    break;
                }
                default:
                    NSLog(@"Failed to write movie: %@", self.movieWriter.error);
                    break;
            }
        }];
    });
}

#pragma mark - setter/getter
- (NSURL *)movieURL {
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:SCMovieFileName];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
    return fileURL;
}

#pragma mark - test
/// 保存视频
- (void)saveMovieToCameraRoll:(NSURL *)url
                   authHandle:(void (^)(BOOL, PHAuthorizationStatus))authHandle
                   completion:(void (^)(BOOL, NSError * _Nullable))completion {
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if (status != PHAuthorizationStatusAuthorized) {
            authHandle(false, status);
            return;
        }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *videoRequest = [PHAssetCreationRequest creationRequestForAsset];
            [videoRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:url options:nil];
        } completionHandler:^( BOOL success, NSError * _Nullable error ) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }];
    }];
}

@end
