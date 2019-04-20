//
//  SCPhotoManager.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/20.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCPhotoManager.h"
#import "UIImage+SCCamera.h"

@interface SCPhotoManager () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, copy) SCPhotoManagerStillImageCompletion stillPhotoCompletion;
@property (nonatomic, copy) SCPhotoManagerLiveImageCompletion livePhotoCompletion;
@property (nonatomic, assign) CGRect currentPreviewFrame;
@property (nonatomic, strong) NSData *photoData;
@end

@implementation SCPhotoManager

#pragma mark - init
- (instancetype)initWithPhotoOutput:(AVCapturePhotoOutput*)photoOutput {
    if (self = [super init]) {
        self.photoOutput = photoOutput;
    }
    return self;
}

+ (instancetype)photoManager:(AVCapturePhotoOutput*)photoOutput {
    return [[self alloc] initWithPhotoOutput:photoOutput];
}

#pragma mark - public method
- (void)takeStillPhoto:(AVCaptureVideoPreviewLayer*)previewLayer
            completion:(SCPhotoManagerStillImageCompletion)completion {
    NSAssert(self.photoOutput, @"photoOutput 不可为空");
    self.currentPreviewFrame = previewLayer.frame;
    self.stillPhotoCompletion = completion;
    
    AVCaptureConnection *connection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.supportsVideoOrientation) {
        connection.videoOrientation = previewLayer.connection.videoOrientation;
    }
    
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecJPEG]) {
        NSDictionary *format = @{AVVideoCodecKey: AVVideoCodecJPEG};
        photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
    }
    
    photoSettings.autoStillImageStabilizationEnabled = YES;
    
    [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

- (void)takeLivePhoto:(AVCaptureVideoPreviewLayer*)previewLayer
           completion:(SCPhotoManagerLiveImageCompletion)completion {
    NSAssert(self.photoOutput, @"photoOutput 不可为空");
    NSAssert(self.photoOutput.livePhotoCaptureEnabled, @"需要在捕捉会话启动前设置 livePhotoCaptureEnabled");
    self.currentPreviewFrame = previewLayer.frame;
    self.livePhotoCompletion = completion;
    
    AVCaptureConnection *connection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.supportsVideoOrientation) {
        connection.videoOrientation = previewLayer.connection.videoOrientation;
    }
    
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    // 暂时不用 AVVideoCodecHEVC
    NSString *livePhotoMovieFileName = [[NSUUID UUID] UUIDString];
    NSString *livePhotoMovieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[livePhotoMovieFileName stringByAppendingPathExtension:@"mov"]];
    photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
    
    [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

#pragma mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    // 拍摄准备完毕
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    // 曝光开始
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    // 曝光结束
}

/// ios(11.0) 才有用的
//- (void) captureOutput:(AVCapturePhotoOutput*)captureOutput didFinishProcessingPhoto:(AVCapturePhoto*)photo error:(nullable NSError*)error  API_AVAILABLE(ios(11.0)) {}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {
    if (error) {
        if (self.stillPhotoCompletion) {
            self.stillPhotoCompletion(nil, nil, nil, error);
            self.stillPhotoCompletion = nil;
        }
        if (self.livePhotoCompletion) {
            self.livePhotoCompletion(nil, nil, error);
            self.livePhotoCompletion = nil;
        }
        return;
    }
    // 1. 获取 originImage
    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:photoSampleBuffer];
    self.photoData = imageData;
    // 静态图片处理
    if (self.stillPhotoCompletion) {
        UIImage *originImage = [[UIImage alloc] initWithData:imageData];
        originImage = [originImage fixOrientation];
        // 2. 获取 scaledImage
        CGFloat width = self.currentPreviewFrame.size.width;
        CGFloat height = self.currentPreviewFrame.size.height;
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize size = CGSizeMake(width*scale, height*scale);
        UIImage *scaledImage = [originImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill size:size interpolationQuality:kCGInterpolationHigh];
        // 3. 获取 croppedImage
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) * 0.5, (scaledImage.size.height - size.height) * 0.5, size.width, size.height);
        UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
        // 4. 回调
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stillPhotoCompletion(originImage, scaledImage, croppedImage, nil);
            self.stillPhotoCompletion = nil;
        });
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    // 完成 Live Photo 停止拍摄
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
    if (error) {
        if (self.livePhotoCompletion) {
            self.livePhotoCompletion(nil, nil, error);
            self.livePhotoCompletion = nil;
        }
        return;
    }
    if (self.livePhotoCompletion) {
        self.livePhotoCompletion(outputFileURL, self.photoData, nil);
        self.livePhotoCompletion = nil;
    }
}

- (void) captureOutput:(AVCapturePhotoOutput*)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings*)resolvedSettings error:(NSError*)error {
    // 完成拍摄，可以在此处保存
}

#pragma mark - private method


#pragma mark - setter/getter
- (void)setPhotoOutput:(AVCapturePhotoOutput *)photoOutput {
    _photoOutput = photoOutput;
}

@end

