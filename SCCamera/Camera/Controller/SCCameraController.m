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

@end

@implementation SCCameraController {
    bool isFirstLoad;
}

- (void)close:(UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

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

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [SCCameraManager new];
    self.manager.delegate = self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.manager stop];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.manager startUp];
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
- (IBAction)takePhotoClick:(id)sender {
    
}

- (IBAction)closeClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)transformAction:(UIButton *)sender {
    self.transformBtn.selected = !self.transformBtn.selected;
    [self.manager changeCameraInputDeviceisFront:sender.selected];
    if (self.transformBtn.selected == YES) { // 切换为前置镜头关闭闪光灯
        self.lightSwitchBtn.selected = NO;
        [self.manager closeFlashLight];
    }
}

- (IBAction)lightSwitchAcrion:(UIButton *)sender {
    if (self.transformBtn.selected) { // 当前为前置镜头的时候不能打开闪光灯
        return;
    }
    self.lightSwitchBtn.selected = !self.lightSwitchBtn.selected;
    if (self.lightSwitchBtn.selected) {
        [self.manager openFlashLight];
    } else {
        [self.manager closeFlashLight];
    }
}

@end

