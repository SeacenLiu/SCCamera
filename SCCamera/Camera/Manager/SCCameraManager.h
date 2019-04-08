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

@class SCCameraManager;
@protocol SCCameraManagerDelegate <NSObject>

- (void)cameraManagerDidLoadSession:(SCCameraManager*)manager session:(AVCaptureSession*)session;

@end

@interface SCCameraManager : NSObject

@property (nonatomic, weak) id<SCCameraManagerDelegate> delegate;

@property (nonatomic, strong) AVCaptureSession *session;

/** 开启Session */
- (void)startUp;

/** 暂停Session */
- (void)stop;

/** 拍照方法 */
- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer handle:(void (^)(UIImage *originImage, UIImage *scaledImage, UIImage *croppedImage))handle;

/** 设置闪光灯 */
- (void)setFlashMode:(AVCaptureFlashMode)mode;

/** 切换前后置摄像头 */
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;

/** 聚焦 */
- (void)focusInPoint:(CGPoint)devicePoint;

/** 曝光 */
- (void)exposePoint:(CGPoint)point;

#pragma mark - 视频处理

@end

NS_ASSUME_NONNULL_END
