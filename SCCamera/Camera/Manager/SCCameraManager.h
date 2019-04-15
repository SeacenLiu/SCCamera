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
- (void)switchCamera:(AVCaptureSession *)session
                 old:(AVCaptureDeviceInput *)oldInput
                 new:(AVCaptureDeviceInput *)newInput
              handle:(CameraHandleError)handle;

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
               device:(AVCaptureDevice*)device
        atDevicePoint:(CGPoint)point
monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
               handle:(CameraHandleError)handle;

- (void)iso:(AVCaptureDevice *)device factor:(CGFloat)factor handle:(CameraHandleError)handle;

- (void)changeFlash:(AVCaptureDevice*)device mode:(AVCaptureFlashMode)mode handle:(CameraHandleError)handle;

- (void)changeTorch:(AVCaptureDevice*)device mode:(AVCaptureTorchMode)mode handle:(CameraHandleError)handle;

- (void)zoom:(AVCaptureDevice*)device factor:(CGFloat)factor handle:(CameraHandleError)handle;

- (void)whiteBalance:(AVCaptureDevice*)device mode:(AVCaptureWhiteBalanceMode)mode handle:(CameraHandleError)handle;

- (void)resetFocusAndExpose:(AVCaptureDevice*)device handle:(CameraHandleError)handle;
@end

NS_ASSUME_NONNULL_END
