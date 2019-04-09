//
//  SCCameraManager.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraManager.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+SCCamera.h"
#import "AVCaptureDevice+SCCategory.h"

// TODO: - 判断权限

@interface SCCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
// queue
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t videoQueue;
@property (nonatomic) dispatch_queue_t audioQueue;
@property (nonatomic) dispatch_queue_t metaQueue;
// 输入
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *currentCameraInput;
// Connection
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
// 输出
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metaOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput; // iOS10 AVCapturePhotoOutput
// 判断是否手动对焦
@property (nonatomic, assign) BOOL isManualFocus;
// 录制
@property (nonatomic, assign, getter=isRecording) BOOL recording;

@end

@implementation SCCameraManager

#pragma mark - init
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc {
    // 感觉不太需要 stop
//    [self stop];
    NSLog(@"SCCameraManager dealloc");
}

#pragma mark - 缩放
- (void)zoom:(AVCaptureDevice *)device factor:(CGFloat)factor handle:(CameraHandleError)handle {
    // TODO: - 缩放
}

#pragma mark - 聚焦
- (void)focus:(AVCaptureDevice *)device point:(CGPoint)point handle:(CameraHandleError)handle {
    self.isManualFocus = YES;
    NSLog(@"%@", NSStringFromCGPoint(point));
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:point monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    [self settingWithDevice:[self.currentCameraInput device] config:^(AVCaptureDevice *device, NSError *error) {
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
            [device setFocusMode:focusMode];
            [device setFocusPointOfInterest:point];
        }
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:exposureMode];
            [device setExposurePointOfInterest:point];
        }
        [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
    }];
}

- (void)resetFocusAndExposure:(AVCaptureDevice *)device handle:(CameraHandleError)handle {
    
}

#pragma mark - 曝光
static const NSString *CameraAdjustingExposureContext;
- (void)expose:(AVCaptureDevice *)device point:(CGPoint)point handle:(CameraHandleError)handle {
    BOOL supported = [device isExposurePointOfInterestSupported] &&
    [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure];
    if (supported) {
        [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&CameraAdjustingExposureContext];
            }
        }];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (context == &CameraAdjustingExposureContext) {
        AVCaptureDevice *device = (AVCaptureDevice *)object;
        if (!device.isAdjustingExposure && [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [object removeObserver:self forKeyPath:@"adjustingExposure" context:&CameraAdjustingExposureContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                if ([device lockForConfiguration:&error]) {
                    device.exposureMode = AVCaptureExposureModeLocked;
                    [device unlockForConfiguration];
                } else {
                    NSLog(@"%@", error);
                }
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)changeFlash:(AVCaptureDevice *)device mode:(AVCaptureFlashMode)mode handle:(CameraHandleError)handle {
    
}

- (void)changeTorch:(AVCaptureDevice *)device model:(AVCaptureTorchMode)mode handle:(CameraHandleError)handle {
    
}

- (AVCaptureFlashMode)flashMode:(AVCaptureDevice *)device handle:(CameraHandleError)handle {
    
    return NULL;
}

- (AVCaptureTorchMode)torchMode:(AVCaptureDevice *)device handle:(CameraHandleError)handle {
    
    return NULL;
}

#pragma mark - 拍照操作
- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer handle:(void (^)(UIImage *, UIImage *, UIImage *))handle {
    NSLog(@"takePhoto");
//    dispatch_async(self.sessionQueue, ^{
//        NSLog(@"queue");
        AVCaptureConnection* stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            NSLog(@"call back");
            if (!imageDataSampleBuffer) {
                return;
            }
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *originImage = [[UIImage alloc] initWithData:imageData];
            
            CGFloat squareLength = previewLayer.bounds.size.width;
            CGFloat previewLayerH = previewLayer.bounds.size.height;
            CGFloat scale = [[UIScreen mainScreen] scale];
            CGSize size = CGSizeMake(squareLength*scale, previewLayerH*scale);
            
            // 输出 scaledImage 的时候 imageOrientation 被矫正
            UIImage *scaledImage = [originImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill size:size interpolationQuality:kCGInterpolationHigh];
            
            CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2, (scaledImage.size.height - size.height) / 2, size.width, size.height);
            UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
            
            UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
            if (orientation != UIDeviceOrientationPortrait) {
                CGFloat degree = 0;
                if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                    degree = 180; //M_PI;
                } else if (orientation == UIDeviceOrientationLandscapeLeft) {
                    degree = -90; //-M_PI_2;
                } else if (orientation == UIDeviceOrientationLandscapeRight) {
                    degree = 90; //M_PI_2;
                }
                if (self.currentCameraInput == self.frontCameraInput) {
                    degree = -degree;
                }
                croppedImage = [croppedImage rotatedByDegrees:degree];
                scaledImage = [scaledImage rotatedByDegrees:degree];
                originImage = [originImage rotatedByDegrees:degree];
            }
            // originImage.imageOrientation 是 3 代表旋转 90 度之后是正的
            // scaledImage.imageOrientation 是 0 代表当前就是正的
            originImage = [originImage fixOrientation];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handle) {
                    handle(originImage,scaledImage,croppedImage);
                }
            });
        }];
//    });
}

#pragma mark - 自动白平衡
- (void)openAutoWhiteBalance {
    [self settingWithDevice:self.currentCameraInput.device config:^(AVCaptureDevice *device, NSError *error) {
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
    }];
}

#pragma mark - 闪光灯
- (void)setFlashMode:(AVCaptureFlashMode)mode {
    AVCaptureDevice *device = self.currentCameraInput.device;
    if ([device isFlashModeSupported:mode]) {
        [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            device.flashMode = mode;
        }];
    }
}

#pragma mark - 切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    dispatch_async(self.sessionQueue, ^{
        [self.session beginConfiguration];
        if (isFront) {
            [self.session removeInput:self.backCameraInput];
            if ([self.session canAddInput:self.frontCameraInput]) {
                [self.session addInput:self.frontCameraInput];
                self.currentCameraInput = self.frontCameraInput;
            }
        } else {
            [self.session removeInput:self.frontCameraInput];
            if ([self.session canAddInput:self.backCameraInput]) {
                [self.session addInput:self.backCameraInput];
                self.currentCameraInput = self.backCameraInput;
            }
        }
        [self.session commitConfiguration];
    });
}

#pragma mark - getter/setter


#pragma mark - Tool
/** 在sessionQueue中设置Device */
- (void)settingWithDevice:(AVCaptureDevice*)device config:(void(^)(AVCaptureDevice* device, NSError* error))config {
    [device settingWithConfig:config queue:NULL];
//    dispatch_async(_sessionQueue, ^{
//        NSError *error;
//        if ([device lockForConfiguration:&error]) {
//            config(device, nil);
//            [device unlockForConfiguration];
//        }
//        if (error) {
//            config(nil, error);
//        }
//    });
}

@end
