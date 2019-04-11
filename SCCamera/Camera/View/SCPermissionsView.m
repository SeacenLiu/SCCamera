//
//  SCPermissionsView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/11.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCPermissionsView.h"

@interface SCPermissionsView ()
@property (nonatomic, strong) UIButton *cameraBtn;
@property (nonatomic, strong) UIButton *microphoneBtn;
@end

@implementation SCPermissionsView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
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
        [_cameraBtn sizeToFit];
    }
    return _cameraBtn;
}

- (UIButton *)microphoneBtn {
    if (_microphoneBtn == nil) {
        _microphoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_microphoneBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_microphoneBtn setTitle:@"获取麦克风权限" forState:UIControlStateNormal];
        [_microphoneBtn sizeToFit];
    }
    return _microphoneBtn;
}

@end
