//
//  SCMovieFileOutManager.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/12.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCMovieFileOutManager.h"

@interface SCMovieFileOutManager () <AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) NSURL *movieURL;
@end

@implementation SCMovieFileOutManager

- (instancetype)init
{
    self = [super init];
    if (self) {
         _movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"movie.mov"]];
    }
    return self;
}

/// 录制状态
- (BOOL)isRecording {
    return self.movieFileOutput.isRecording;
}


/// 开始录制
- (void)start:(AVCaptureVideoOrientation)orientation {
    NSAssert(self.movieFileOutput, @"必须给movieFileOutput赋值");
    if (!self.isRecording) {
        AVCaptureConnection *videoConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (videoConnection.supportsVideoStabilization) {
            videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        if (videoConnection.supportsVideoOrientation) {
            videoConnection.videoOrientation = orientation;
        }
        [self.movieFileOutput startRecordingToOutputFileURL:self.movieURL recordingDelegate:self];
    }
}

/// 停止录制
- (void)stop{
    if (self.isRecording) {
        [self.movieFileOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(nonnull AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)outputFileURL fromConnections:(nonnull NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    if (error) {
        if ([_delegate respondsToSelector:@selector(movieFileOutManagerHandleError:error:)]) {
            [_delegate movieFileOutManagerHandleError:self error:error];
        }
    } else {
        if ([_delegate respondsToSelector:@selector(movieFileOutManagerDidFinishRecord:outputFileURL:)]) {
            [_delegate movieFileOutManagerDidFinishRecord:self outputFileURL:outputFileURL];
        }
    }
}

/// 保存到相册
- (void)saveMovieToCameraRoll:(NSURL *)url
                   authHandle:(void(^)(BOOL success, PHAuthorizationStatus status))authHandle
                   completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
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
