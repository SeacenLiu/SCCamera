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

#pragma mark - 聚焦
- (void)focus:(AVCaptureDevice *)device point:(CGPoint)point handle:(CameraHandleError)handle {
    NSLog(@"%@", NSStringFromCGPoint(point));
    AVCaptureFocusMode focusMode = AVCaptureFocusModeAutoFocus;
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    BOOL monitorSubjectAreaChange = YES;
    [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
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
