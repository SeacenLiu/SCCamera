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

@interface SCCameraController () <SCCameraManagerDelegate>

@property (weak, nonatomic) IBOutlet SCVideoPreviewView *preview;
@property (weak, nonatomic) IBOutlet UIButton *transformBtn;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *lightSwitchBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property (nonatomic, strong) SCCameraManager *manager;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

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
    // 手势添加
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusingTapClcik:)];
    [self.preview addGestureRecognizer:self.tap];
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

#pragma mark - SCCameraManagerDelegate
- (void)cameraManagerDidLoadSession:(SCCameraManager *)manager session:(AVCaptureSession *)session {
    self.preview.captureSession = session;
}

#pragma mark - 操作
/** 聚焦手势 */
- (void)focusingTapClcik:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.preview];
    CGPoint devicePoint = [self.preview.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self.manager focusInPoint:devicePoint];
}

- (IBAction)takePhotoClick:(id)sender {
    NSLog(@"拍照操作");
}

- (IBAction)closeClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)transformAction:(UIButton *)sender {
    self.transformBtn.selected = !self.transformBtn.selected;
    [self.manager changeCameraInputDeviceisFront:sender.selected];
    // TODO: - 闪光灯状态问题
}

- (IBAction)lightSwitchAcrion:(UIButton *)sender {
    self.lightSwitchBtn.selected = !self.lightSwitchBtn.selected;
    if (self.lightSwitchBtn.selected) {
        [self.manager setFlashMode:AVCaptureFlashModeOn];
    } else {
        [self.manager setFlashMode:AVCaptureFlashModeOff];
    }
}

#pragma mark - 方向变化处理
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.preview.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

@end

