//
//  SCCameraController.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraController.h"
#import "SCCameraManager.h"


@interface SCCameraController ()

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIButton *transformBtn;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *lightSwitchBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;

@property (nonatomic, strong) UIImage *detectImg;

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
    isFirstLoad = true;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.manager stop];
    self.manager.canDetect = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isFirstLoad) {
        [self.manager startUp];
        self.manager.canDetect = YES;
        isFirstLoad = false;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!isFirstLoad) {
        [self.manager startUp];
        self.manager.canDetect = YES;
    }
}

- (IBAction)closeClick:(UIButton *)sender {
    if (self.showImageView.isHidden) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.lightSwitchBtn setHidden:NO];
        [self.transformBtn setHidden:NO];
        [self.doneBtn setHidden:YES];
        [self.takePhotoBtn setHidden:NO];
        [self.showImageView setHidden:YES];
        self.showImageView.image = nil;
        [self.manager startUp];
    }
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

