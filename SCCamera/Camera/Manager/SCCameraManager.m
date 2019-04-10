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
    [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
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
    [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
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
        [device unlockForConfiguration];
    }];
}

/// 闪光灯
- (void)changeFlash:(AVCaptureDevice *)device mode:(AVCaptureFlashMode)mode handle:(CameraHandleError)handle {
    [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
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
    [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
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
- (void)openAutoWhiteBalance:(AVCaptureDevice *)device {
    [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
    }];
}

#pragma mark - Tool
- (void)settingWithDevice:(AVCaptureDevice*)device config:(void(^)(AVCaptureDevice* device, NSError* error))config {
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        config(device, nil);
        [device unlockForConfiguration];
    }
    if (error) {
        config(nil, error);
    }
}

@end
