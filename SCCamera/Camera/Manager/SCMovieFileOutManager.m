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
@property (nonatomic, copy) void(^finishHandle)(NSURL *videoURL, NSError *error);
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
- (void)start:(AVCaptureVideoOrientation)orientation handle:(void(^)(NSError *error))handle {
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
- (void)stop:(void(^)(NSURL *url, NSError *error))handle {
    if (self.isRecording) {
        self.finishHandle = handle;
        [self.movieFileOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(nonnull AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)outputFileURL fromConnections:(nonnull NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    self.finishHandle(outputFileURL, error);
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
