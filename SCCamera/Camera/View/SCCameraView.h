//
//  SCCameraView.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SCCameraView;
@protocol SCCameraViewDelegate <NSObject>
@optional;

#pragma mark - 相机操作
/// 闪光灯
- (void)flashLightAction:(SCCameraView *)cameraView isOn:(BOOL)isOn handle:(void(^)(NSError *error))handle;
/// 补光
- (void)torchLightAction:(SCCameraView *)cameraView isOn:(BOOL)isOn handle:(void(^)(NSError *error))handle;
/// 转换摄像头
- (void)switchCameraAction:(SCCameraView *)cameraView isFront:(BOOL)isFront handle:(void(^)(NSError *error))handle;
/// 聚焦&曝光
- (void)focusAndExposeAction:(SCCameraView *)cameraView point:(CGPoint)point handle:(void(^)(NSError *error))handle;
/// 缩放
- (void)zoomAction:(SCCameraView *)cameraView factor:(CGFloat)factor handle:(void(^)(NSError *error))handle;

#pragma mark - 拍照
/// 拍照
- (void)takePhotoAction:(SCCameraView *)cameraView;

#pragma mark - 录制视频
/// 开始录制视频
- (void)startRecordVideoAction:(SCCameraView *)cameraView;
/// 停止录制视频
- (void)stopRecordVideoAction:(SCCameraView *)cameraView;

#pragma mark - 其他
/// 改变拍摄类型 1：拍照 2：视频
- (void)didChangeTypeAction:(SCCameraView *)cameraView type:(NSInteger)type;
/// 取消
- (void)cancelAction:(SCCameraView *)cameraView;

@end

@class SCVideoPreviewView;
@interface SCCameraView : UIView

@property (nonatomic, weak) id<SCCameraViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet SCVideoPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

/// 指定构造函数
+ (instancetype)cameraView:(CGRect)frame;

- (void)runFocusAnimation:(CGPoint)center;

@end

NS_ASSUME_NONNULL_END
