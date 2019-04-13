//
//  SCMovieManager.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCMovieManager.h"

@interface SCMovieManager ()
@property (nonatomic, assign) BOOL readyToRecordVideo;
@property (nonatomic, assign) BOOL readyToRecordAudio;
@property (nonatomic) dispatch_queue_t movieWritingQueue;
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic, strong) AVAssetWriter *movieWriter;
@property (nonatomic, strong) AVAssetWriterInput *movieAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *movieVideoInput;
@end

@implementation SCMovieManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _movieWritingQueue = dispatch_queue_create("com.seacen.movieWritingQueue", DISPATCH_QUEUE_SERIAL);
        _movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"movie.mov"]];
        _referenceOrientation = AVCaptureVideoOrientationPortrait;
    }
    return self;
}

- (void)start:(void(^)(NSError *error))handle {
    if (!self.isRecording) {
        [self removeFile:_movieURL];
        dispatch_async(_movieWritingQueue, ^{
            NSError *error;
            if (!self.movieWriter) {
                self.movieWriter = [[AVAssetWriter alloc] initWithURL:self.movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
            }
            if (error) {
                handle(error);
            } else {
                self->_recording = YES;
            }
        });
    }
}

- (void)stop:(void(^)(NSURL *url, NSError *error))handle {
    if (self.isRecording) {
        _readyToRecordVideo = NO;
        _readyToRecordAudio = NO;
        dispatch_async(_movieWritingQueue, ^{
            [self.movieWriter finishWritingWithCompletionHandler:^(){
                self->_recording = NO;
                if (self.movieWriter.status == AVAssetWriterStatusCompleted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        handle(self.movieURL, nil);
                    });
                } else {
                    handle(nil, self.movieWriter.error);
                }
                self.movieWriter = nil;
            }];
        });
    }
}

- (void)writeData:(AVCaptureConnection *)connection video:(AVCaptureConnection*)video audio:(AVCaptureConnection *)audio buffer:(CMSampleBufferRef)buffer {
    if (self.isRecording == false) {
        return;
    }
    CFRetain(buffer);
    dispatch_async(_movieWritingQueue, ^{
        if (connection == video) {
            // 视频处理
            if (!self.readyToRecordVideo) {
                // 视频写入配置
                self.readyToRecordVideo = [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(buffer)] == nil;
            }
            if ([self inputsReadyToRecord]) {
                // 写入视频
                [self writeSampleBuffer:buffer ofType:AVMediaTypeVideo];
            }
        } else if (connection == audio) {
            // 音频处理
            if (!self.readyToRecordAudio) {
                // 音频写入配置
                self.readyToRecordAudio = [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(buffer)] == nil;
            }
            if ([self inputsReadyToRecord]) {
                // 写入音频
                [self writeSampleBuffer:buffer ofType:AVMediaTypeAudio];
            }
        }
        CFRelease(buffer);
    });
}

/// 写入音视频数据
- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType {
    if (_movieWriter.status == AVAssetWriterStatusUnknown) {
        if ([_movieWriter startWriting]) {
            [_movieWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        } else {
            NSLog(@"%@", _movieWriter.error);
        }
        return;
    }
    if (_movieWriter.status == AVAssetWriterStatusWriting) {
        if (mediaType == AVMediaTypeVideo) {
            if (!_movieVideoInput.readyForMoreMediaData) {
                return;
            }
            if (![_movieVideoInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"%@", _movieWriter.error);
            }
        } else if (mediaType == AVMediaTypeAudio) {
            if (!_movieAudioInput.readyForMoreMediaData) {
                return;
            }
            if (![_movieAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"%@", _movieWriter.error);
            }
        }
    }
}

- (BOOL)inputsReadyToRecord{
    return _readyToRecordVideo && _readyToRecordAudio;
}

/// 音频源数据写入配置
- (NSError *)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription {
    size_t aclSize = 0;
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    const AudioChannelLayout *channelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription,&aclSize);
    NSData *dataLayout = aclSize > 0 ? [NSData dataWithBytes:channelLayout length:aclSize] : [NSData data];
    NSDictionary *settings = @{AVFormatIDKey: [NSNumber numberWithInteger: kAudioFormatMPEG4AAC],
                               AVSampleRateKey: [NSNumber numberWithFloat: currentASBD->mSampleRate],
                               AVChannelLayoutKey: dataLayout,
                               AVNumberOfChannelsKey: [NSNumber numberWithInteger: currentASBD->mChannelsPerFrame],
                               AVEncoderBitRatePerChannelKey: [NSNumber numberWithInt: 64000]};
    
    if ([_movieWriter canApplyOutputSettings:settings forMediaType: AVMediaTypeAudio]) {
        _movieAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType: AVMediaTypeAudio outputSettings:settings];
        _movieAudioInput.expectsMediaDataInRealTime = YES;
        if ([_movieWriter canAddInput:_movieAudioInput]) {
            [_movieWriter addInput:_movieAudioInput];
        } else {
            return _movieWriter.error;
        }
    } else {
        return _movieWriter.error;
    }
    return nil;
}

/// 视频源数据写入配置
- (NSError *)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription {
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    NSUInteger numPixels = dimensions.width * dimensions.height;
    CGFloat bitsPerPixel = numPixels < (640 * 480) ? 4.05 : 11.0;
    NSDictionary *compression = @{AVVideoAverageBitRateKey: [NSNumber numberWithInteger: numPixels * bitsPerPixel],
                                  AVVideoMaxKeyFrameIntervalKey: [NSNumber numberWithInteger:30]};
    NSDictionary *settings = @{AVVideoCodecKey: AVVideoCodecH264,
                               AVVideoWidthKey: [NSNumber numberWithInteger:dimensions.width],
                               AVVideoHeightKey: [NSNumber numberWithInteger:dimensions.height],
                               AVVideoCompressionPropertiesKey: compression};
    
    if ([_movieWriter canApplyOutputSettings:settings forMediaType:AVMediaTypeVideo]) {
        _movieVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
        _movieVideoInput.expectsMediaDataInRealTime = YES;
        _movieVideoInput.transform = [self transformFromCurrentVideoOrientationToOrientation:self.referenceOrientation];
        if ([_movieWriter canAddInput:_movieVideoInput]) {
            [_movieWriter addInput:_movieVideoInput];
        } else {
            return _movieWriter.error;
        }
    } else {
        return _movieWriter.error;
    }
    return nil;
}

/// 获取视频旋转矩阵
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation {
    CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
    CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:self.currentOrientation];
    CGFloat angleOffset;
    if (self.currentDevice.position == AVCaptureDevicePositionBack) {
        angleOffset = videoOrientationAngleOffset - orientationAngleOffset + M_PI_2;
    } else {
        angleOffset = orientationAngleOffset - videoOrientationAngleOffset + M_PI_2;
    }
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleOffset);
    return transform;
}

/// 获取视频旋转角度
- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation {
    CGFloat angle = 0.0;
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
    }
    return angle;
}

/// 移除文件
- (void)removeFile:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = fileURL.path;
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"删除视频文件失败：%@", error);
        } else {
            NSLog(@"删除视频文件成功");
        }
    }
}

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
