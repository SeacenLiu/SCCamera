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

@class SCDetectorResultModel;
@protocol SCCameraManagerDelegate <NSObject>



@end

@interface SCCameraManager : NSObject

@property (nonatomic, weak) id<SCCameraManagerDelegate> delegate;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, assign) BOOL faceRecognition;
@property (nonatomic, assign) BOOL isDetectFace;


/** 开启Session */
- (void)startUp;

/** 暂停Session */
- (void)stop;

// 开启闪光灯
- (void)openFlashLight;
// 关闭闪光灯
- (void)closeFlashLight;
// 切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;
// 对焦
- (void)focusInPoint:(CGPoint)devicePoint;

@end

NS_ASSUME_NONNULL_END
