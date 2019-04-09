//
//  SCCameraManager.h
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^_Nullable CameraHandleError)(NSError * _Nullable error);

@interface SCCameraManager : NSObject
- (AVCaptureDeviceInput *)switchCamera:(AVCaptureSession *)session old:(AVCaptureDeviceInput *)oldinput new:(AVCaptureDeviceInput *)newinput handle:(CameraHandleError)handle;

- (void)resetFocusAndExposure:(AVCaptureDevice *)device handle:(CameraHandleError)handle;

- (void)zoom:(AVCaptureDevice *)device factor:(CGFloat)factor handle:(CameraHandleError)handle;

- (void)focus:(AVCaptureDevice *)device point:(CGPoint)point handle:(CameraHandleError)handle;

- (void)expose:(AVCaptureDevice *)device point:(CGPoint)point handle:(CameraHandleError)handle;

- (void)changeFlash:(AVCaptureDevice *)device mode:(AVCaptureFlashMode)mode handle:(CameraHandleError)handle;

- (void)changeTorch:(AVCaptureDevice *)device model:(AVCaptureTorchMode)mode handle:(CameraHandleError)handle;

- (AVCaptureFlashMode)flashMode:(AVCaptureDevice *)device handle:(CameraHandleError)handle;

- (AVCaptureTorchMode)torchMode:(AVCaptureDevice *)device handle:(CameraHandleError)handle;

#pragma mark - 视频处理

@end

NS_ASSUME_NONNULL_END
