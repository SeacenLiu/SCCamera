//
//  SCPermissionsView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/11.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCPermissionsView.h"
#import <AVFoundation/AVCaptureDevice.h>
#import "UIView+SCCategory.h"

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
    BOOL cameraGranted = cameraStatus == AVAuthorizationStatusAuthorized;
    [self btnChange:self.cameraBtn granted:cameraGranted];
    AVAuthorizationStatus microphoneStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    BOOL microphoneGranted = microphoneStatus == AVAuthorizationStatusAuthorized;
    [self btnChange:self.microphoneBtn granted:microphoneGranted];
}

- (void)btnChange:(UIButton*)btn granted:(BOOL)granted {
    [btn setEnabled:!granted];
    // 判断权限都获取了的状态
    if (!self.cameraBtn.enabled && !self.microphoneBtn.enabled) {
        if ([self.delegate respondsToSelector:@selector(permissionsViewDidHasAllPermissions:)]) {
            [self.delegate permissionsViewDidHasAllPermissions:self];
        }
    }
}

- (void)obtainPermission:(UIButton*)sender {
    AVMediaType type = AVMediaTypeVideo;
    if (sender == self.microphoneBtn)
        type = AVMediaTypeAudio;
    switch ([AVCaptureDevice authorizationStatusForMediaType:type]) {
        case AVAuthorizationStatusNotDetermined: {
            // 手动询问
            [AVCaptureDevice requestAccessForMediaType:type completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self btnChange:sender granted:granted];
                });
            }];
            break;
        }
        case AVAuthorizationStatusDenied:
            // 跳转设置界面
            [self openSetting];
            break;
        default:
            break;
    }
}

- (void)openSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)setupUI {
    self.backgroundColor = [UIColor blackColor];
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
        [_cameraBtn setTitle:@"允许访问相机" forState:UIControlStateNormal];
        [_cameraBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_cameraBtn setTitle:@"相机访问权限已启用" forState:UIControlStateDisabled];
        [_cameraBtn addTarget:self action:@selector(obtainPermission:) forControlEvents:UIControlEventTouchUpInside];
        [_cameraBtn sizeToFit];
    }
    return _cameraBtn;
}

- (UIButton *)microphoneBtn {
    if (_microphoneBtn == nil) {
        _microphoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_microphoneBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_microphoneBtn setTitle:@"允许访问麦克风" forState:UIControlStateNormal];
        [_microphoneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [_microphoneBtn setTitle:@"麦克风权限已启用" forState:UIControlStateDisabled];
        [_microphoneBtn addTarget:self action:@selector(obtainPermission:) forControlEvents:UIControlEventTouchUpInside];
        [_microphoneBtn sizeToFit];
    }
    return _microphoneBtn;
}

@end
