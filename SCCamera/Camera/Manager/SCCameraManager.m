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
    // 感觉不太需要 stop
    //    [self stop];
    NSLog(@"SCCameraManager dealloc");
}

#pragma mark - 缩放
- (void)zoom:(AVCaptureDevice *)device factor:(CGFloat)factor handle:(CameraHandleError)handle {
    // TODO: - 缩放
}

#pragma mark - 聚焦&曝光
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
        if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
            device.focusPointOfInterest = point;
            // 需要设置 focusMode 才应用 focusPointOfInterest
            device.focusMode = focusMode;
        }
        if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
        }
        device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
        [device unlockForConfiguration];
    }];
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


#pragma mark - 自动白平衡
- (void)openAutoWhiteBalance {
    //    [self settingWithDevice:self.currentCameraInput.device config:^(AVCaptureDevice *device, NSError *error) {
    //        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
    //            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
    //        }
    //    }];
}

#pragma mark - 闪光灯
- (void)setFlashMode:(AVCaptureFlashMode)mode {
    //    AVCaptureDevice *device = self.currentCameraInput.device;
    //    if ([device isFlashModeSupported:mode]) {
    //        [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
    //            if (error) {
    //                NSLog(@"%@", error);
    //                return;
    //            }
    //            device.flashMode = mode;
    //        }];
    //    }
}

#pragma mark - getter/setter


#pragma mark - Tool
/** 在sessionQueue中设置Device */
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
