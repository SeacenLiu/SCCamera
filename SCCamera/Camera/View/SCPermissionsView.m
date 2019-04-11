//
//  SCPermissionsView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/11.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCPermissionsView.h"
#import <AVFoundation/AVFoundation.h>

@interface SCPermissionsView ()
@property (nonatomic, strong) UIButton *cameraBtn;
@property (nonatomic, strong) UIButton *microphoneBtn;
@end

@implementation SCPermissionsView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        [self setupCurStatus];
    }
    return self;
}

- (void)setupCurStatus {
    /*
     AVAuthorizationStatusNotDetermined = 0,
     AVAuthorizationStatusRestricted    = 1,
     AVAuthorizationStatusDenied        = 2,
     AVAuthorizationStatusAuthorized    = 3,
     */
    AVAuthorizationStatus cameraStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    NSLog(@"%ld", (long)cameraStatus);
    BOOL cameraGranted = cameraStatus == AVAuthorizationStatusAuthorized;
    [self btnChange:self.cameraBtn granted:cameraGranted];
    AVAuthorizationStatus microphoneStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    NSLog(@"%ld", (long)microphoneStatus);
    BOOL microphoneGranted = microphoneStatus == AVAuthorizationStatusAuthorized;
    [self btnChange:self.microphoneBtn granted:microphoneGranted];
}

- (void)btnChange:(UIButton*)btn granted:(BOOL)granted {
    dispatch_async(dispatch_get_main_queue(), ^{
        [btn setEnabled:!granted];
        // 判断权限都获取了的状态
        if (!self.cameraBtn.enabled && !self.microphoneBtn.enabled) {
            if ([self.delegate respondsToSelector:@selector(permissionsViewDidHasAllPermissions:)]) {
                [self.delegate permissionsViewDidHasAllPermissions:self];
            }
        }
    });
}

- (void)getCameraPermission:(UIButton*)sender {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
        // 引导用户到设置修改权限
        NSLog(@"AVMediaTypeVideo");
        return;
    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        [self btnChange:sender granted:granted];
    }];
}

- (void)getMicrophonePermission:(UIButton*)sender {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusDenied) {
        // 引导用户到设置修改权限
        NSLog(@"AVMediaTypeAudio");
        return;
    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        [self btnChange:sender granted:granted];
    }];
}

- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.cameraBtn];
    [self addSubview:self.microphoneBtn];
    [_cameraBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_microphoneBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_cameraBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_cameraBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:0.8 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_microphoneBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_microphoneBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

#pragma mark - lazy
- (UIButton *)cameraBtn {
    if (_cameraBtn == nil) {
        _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_cameraBtn setTitle:@"获取相机权限" forState:UIControlStateNormal];
        [_cameraBtn setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];
        [_cameraBtn setTitle:@"已获取相机权限" forState:UIControlStateDisabled];
        [_cameraBtn addTarget:self action:@selector(getCameraPermission:) forControlEvents:UIControlEventTouchUpInside];
        [_cameraBtn sizeToFit];
    }
    return _cameraBtn;
}

- (UIButton *)microphoneBtn {
    if (_microphoneBtn == nil) {
        _microphoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_microphoneBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_microphoneBtn setTitle:@"获取麦克风权限" forState:UIControlStateNormal];
        [_microphoneBtn setTitleColor:[UIColor blackColor] forState:UIControlStateDisabled];
        [_microphoneBtn setTitle:@"已获取麦克风权限" forState:UIControlStateDisabled];
        [_microphoneBtn addTarget:self action:@selector(getMicrophonePermission:) forControlEvents:UIControlEventTouchUpInside];
        [_microphoneBtn sizeToFit];
    }
    return _microphoneBtn;
}

@end
