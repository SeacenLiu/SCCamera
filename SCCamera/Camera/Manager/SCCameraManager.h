//
//  SCCameraManager.h
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SCDetectorResultModel;
@protocol SCCameraManagerDelegate <NSObject>

- (void)cameraManagerDetectFaces:(NSArray<SCDetectorResultModel*>*)facesResult;
- (void)cameraManagerDetectFail:(NSError*)error;

@end

@interface SCCameraManager : NSObject

@property (nonatomic, weak) id<SCCameraManagerDelegate> delegate;

@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, assign) BOOL faceRecognition;
@property (nonatomic, copy) void(^getimageBlock)(UIImage *image);
@property (nonatomic, assign) BOOL isStartGetImage; // 是否开始从输出数据流捕捉单一图像帧

@property (nonatomic, assign) BOOL isDetectFace;

- (instancetype)initWithParentView:(UIView *)parent;

- (void)startUp;
- (void)stop;

// 开启闪光灯
- (void)openFlashLight;
// 关闭闪光灯
- (void)closeFlashLight;
// 切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;
// 对焦
- (void)focusInPoint:(CGPoint)devicePoint;

@property (nonatomic, assign) BOOL canDetect;

@end

NS_ASSUME_NONNULL_END
