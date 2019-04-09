//
//  SCCameraController.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraController.h"
#import "SCCameraManager.h"
#import "SCVideoPreviewView.h"
#import "SCCameraResultController.h"
#import "SCCameraView.h"

@interface SCCameraController ()
@property (nonatomic, strong) SCCameraView *cameraView;
@property (nonatomic, strong) SCCameraManager *manager;
@end

@implementation SCCameraController

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [SCCameraManager new];
    self.cameraView = [SCCameraView cameraView:self.view.frame];
    [self.view addSubview:_cameraView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.manager stop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.manager startUp];
}

#pragma mark - 相机操作
/** 聚焦操作 */
/** 曝光操作 */
/** 拍照 */
/** 转换镜头 */
/** 闪光灯设置 */
/** 取消 */

#pragma mark - 方向变化处理
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.cameraView.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

@end

