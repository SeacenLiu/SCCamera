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
@interface SCCameraManager ()
@property (nonatomic, assign) float autoISO;
@end

@implementation SCCameraManager

#pragma mark - init
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc {
    NSLog(@"SCCameraManager dealloc");
}

/// 转换摄像头
- (void)switchCamera:(AVCaptureSession *)session
                                   old:(AVCaptureDeviceInput *)oldInput
                                   new:(AVCaptureDeviceInput *)newInput
                                handle:(CameraHandleError)handle {
    [session beginConfiguration];
    [session removeInput:oldInput];
    if ([session canAddInput:newInput]) {
        [session addInput:newInput];
    } else {
        [session addInput:oldInput];
    }
    [session commitConfiguration];
}

/// 缩放
- (void)zoom:(AVCaptureDevice *)device factor:(CGFloat)factor handle:(CameraHandleError)handle {
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        if (device.activeFormat.videoMaxZoomFactor > factor && factor >= 1.0) {
            [device rampToVideoZoomFactor:factor withRate:4.0];
        }
    }];
}

/// 聚焦&曝光
- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
               device:(AVCaptureDevice*)device
        atDevicePoint:(CGPoint)point
monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
               handle:(CameraHandleError)handle {
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        // 聚焦
        if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
            device.focusPointOfInterest = point;
            // 需要设置 focusMode 才应用 focusPointOfInterest
            device.focusMode = focusMode;
        }
        // 曝光
        if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
        }
        device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
//        NSLog(@"min: %f max: %f cur: %f", device.activeFormat.minISO, device.activeFormat.maxISO, device.ISO);
        self.autoISO = device.ISO;
    }];
}

/// 曝光ISO设置
- (void)iso:(AVCaptureDevice *)device factor:(CGFloat)factor handle:(CameraHandleError)handle {
    // 0.5 对应的是 self.autoISO
    float margin = MIN(self.autoISO-device.activeFormat.minISO, device.activeFormat.maxISO-self.autoISO);
    float min = self.autoISO - margin;
    float max = self.autoISO + margin;
    float val = min + (max-min) * factor;
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        __weak typeof(device) weakDevice = device;
        [device setExposureModeCustomWithDuration:device.exposureDuration ISO:val completionHandler:^(CMTime syncTime) {
            [weakDevice settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
                [device setExposureMode:AVCaptureExposureModeCustom];
            }];
        }];
    }];
}

/// 闪光灯
- (void)changeFlash:(AVCaptureDevice *)device mode:(AVCaptureFlashMode)mode handle:(CameraHandleError)handle {
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        if ([device isFlashModeSupported:mode]) {
            device.flashMode = mode;
        } else {
            // TODO: - 抛出错误 handle(error)
        }
    }];
}

/// 补光
- (void)changeTorch:(AVCaptureDevice *)device mode:(AVCaptureTorchMode)mode handle:(CameraHandleError)handle {
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        if ([device isTorchModeSupported:mode]) {
            device.torchMode = mode;
        } else {
            // TODO: - 抛出错误 handle(error)
        }
    }];
}

/// 自动白平衡
- (void)whiteBalance:(AVCaptureDevice*)device mode:(AVCaptureWhiteBalanceMode)mode handle:(CameraHandleError)handle {
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        if ([device isWhiteBalanceModeSupported:mode]) {
            [device setWhiteBalanceMode:mode];
        } else {
            // TODO: - 抛出错误 handle(error)
        }
    }];
}

/// 重置聚焦&曝光
- (void)resetFocusAndExpose:(AVCaptureDevice*)device handle:(CameraHandleError)handle {
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    BOOL canResetFocus = [device isFocusPointOfInterestSupported] &&
    [device isFocusModeSupported:focusMode];
    BOOL canResetExposure = [device isExposurePointOfInterestSupported] &&
    [device isExposureModeSupported:exposureMode];
    CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
    [device settingWithConfig:^(AVCaptureDevice *device, NSError *error) {
        if (error) {
            handle(error);
            return;
        }
        if (canResetFocus) {
            device.focusPointOfInterest = centerPoint;
            device.focusMode = focusMode;
        }
        if (canResetExposure) {
            device.exposurePointOfInterest = centerPoint;
            device.exposureMode = exposureMode;
        }
        self.autoISO = device.ISO;
    }];
}

@end
