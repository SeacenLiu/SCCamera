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

// TODO: - 聚焦，曝光，人脸检测动画

@interface SCCameraController () <SCCameraManagerDelegate>

@property (weak, nonatomic) IBOutlet SCVideoPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *transformBtn;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *lightSwitchBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property (nonatomic, strong) SCCameraManager *manager;

@end

@implementation SCCameraController {
    bool isFirstLoad;
}

- (void)close:(UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [SCCameraManager new];
    self.manager.delegate = self;
    [self addGestureRecognizers];
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

#pragma mark - 手势添加
- (void)addGestureRecognizers {
    // 单击 -> 聚焦
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusingTapClcik:)];
    [self.previewView addGestureRecognizer:tap];
    // 双击 -> 曝光
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exposeTabClick:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.previewView addGestureRecognizer:doubleTap];
    // 手势冲突
    [tap requireGestureRecognizerToFail:doubleTap];
}

#pragma mark - SCCameraManagerDelegate
- (void)cameraManagerDidLoadSession:(SCCameraManager *)manager session:(AVCaptureSession *)session {
    self.previewView.captureSession = session;
}

#pragma mark - 相机操作
/** 聚焦操作 */
- (void)focusingTapClcik:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.previewView];
    CGPoint devicePoint = [self.previewView.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self.manager focusInPoint:devicePoint];
}

/** 曝光操作 */
- (void)exposeTabClick:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.previewView];
    [self.manager exposePoint:point];
}

/** 拍照 */
- (IBAction)takePhotoClick:(id)sender {
    [self.takePhotoBtn setEnabled:NO];
    [self.manager takePhoto:self.previewView.videoPreviewLayer handle:^(UIImage * _Nonnull originImage, UIImage * _Nonnull scaledImage, UIImage * _Nonnull croppedImage) {
        [self.takePhotoBtn setEnabled:YES];
        SCCameraResultController *rc = [SCCameraResultController new];
        rc.img = croppedImage;
        [self presentViewController:rc animated:YES completion:nil];
    }];
}

/** 转换镜头 */
- (IBAction)transformAction:(UIButton *)sender {
    self.transformBtn.selected = !self.transformBtn.selected;
    [self.manager changeCameraInputDeviceisFront:sender.selected];
    // 闪光灯暂时解决方案
    if (self.lightSwitchBtn.selected) {
        [self.manager setFlashMode:AVCaptureFlashModeOn];
    } else {
        [self.manager setFlashMode:AVCaptureFlashModeOff];
    }
}

/** 闪光灯设置 */
- (IBAction)lightSwitchClick:(UIButton *)sender {
    self.lightSwitchBtn.selected = !self.lightSwitchBtn.selected;
    if (self.lightSwitchBtn.selected) {
        [self.manager setFlashMode:AVCaptureFlashModeOn];
    } else {
        [self.manager setFlashMode:AVCaptureFlashModeOff];
    }
}

/** 取消 */
- (IBAction)closeClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 方向变化处理
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

@end

