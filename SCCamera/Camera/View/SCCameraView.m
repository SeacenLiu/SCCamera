//
//  SCCameraView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraView.h"
#import "SCVideoPreviewView.h"
#import "UIView+SCCategory.h"

@interface SCCameraView ()
/// 聚焦动画 view
@property(nonatomic, strong) UIView *focusView;
/// 曝光动画 view
@property(nonatomic, strong) UIView *exposureView;
@end

// TODO: - 聚焦，曝光，人脸检测动画
@implementation SCCameraView

+ (instancetype)cameraView:(CGRect)frame {
    SCCameraView *view = (SCCameraView*)[[UINib nibWithNibName:@"SCCameraView" bundle:nil] instantiateWithOwner:self options:nil][0];
    view.frame = frame;
    [view addGestureRecognizers];
    return view;
}

#pragma mark - 手势添加
- (void)addGestureRecognizers {
    // 单击 -> 聚焦
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusingTapClcik:)];
    [self.previewView addGestureRecognizer:tap];
}

#pragma mark - 相机操作
- (void)focusingTapClcik:(UITapGestureRecognizer *)tap {
    if ([_delegate respondsToSelector:@selector(focusAndExposeAction:point:handle:)]) {
        CGPoint point = [tap locationInView:self.previewView];
        [self runFocusAnimation:self.focusView point:point];
        [_delegate focusAndExposeAction:self point:[self.previewView captureDevicePointForPoint:point] handle:^(NSError * _Nonnull error) {
            // TODO: - handle error
        }];
    }
}

- (IBAction)flashLightClick:(UIButton*)sender {
    if ([self.delegate respondsToSelector:@selector(flashLightAction:isOn:handle:)]) {
        [sender setSelected:!sender.isSelected];
        [_delegate flashLightAction:self isOn:sender.isSelected handle:^(NSError * _Nonnull error) {
            // TODO: - handle error
        }];
    }
}

- (IBAction)torchLightClick:(UIButton*)sender {
    if ([self.delegate respondsToSelector:@selector(torchLightAction:isOn:handle:)]) {
        [sender setSelected:!sender.isSelected];
        [_delegate torchLightAction:self isOn:sender.isSelected handle:^(NSError * _Nonnull error) {
            // TODO: - handle error
        }];
    }
}

- (IBAction)switchCameraClick:(UIButton*)sender {
    if ([_delegate respondsToSelector:@selector(switchCameraAction:isFront:handle:)]) {
        [sender setSelected:!sender.isSelected];
        [_delegate switchCameraAction:self isFront:sender.isSelected handle:^(NSError * _Nonnull error) {
            // TODO: - handle error
        }];
    }
}

- (IBAction)cancelClick:(id)sender {
    if ([_delegate respondsToSelector:@selector(cancelAction:)]) {
        [_delegate cancelAction:self];
    }
}

- (IBAction)takePhotoClick:(id)sender {
    if ([_delegate respondsToSelector:@selector(takePhotoAction:)]) {
        [_delegate takePhotoAction:self];
    }
}

#pragma mark - Animation
/// 聚焦、曝光动画
-(void)runFocusAnimation:(UIView *)view point:(CGPoint)point {
    view.center = point;
    view.hidden = NO;
    [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
    } completion:^(BOOL complete) {
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            view.hidden = YES;
            view.transform = CGAffineTransformIdentity;
        });
    }];
}

/// 自动聚焦、曝光动画
- (void)runResetAnimation {
    self.focusView.center = CGPointMake(self.previewView.width/2, self.previewView.height/2);
    self.exposureView.center = CGPointMake(self.previewView.width/2, self.previewView.height/2);;
    self.exposureView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    self.focusView.hidden = NO;
    self.focusView.hidden = NO;
    [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.focusView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
        self.exposureView.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0);
    } completion:^(BOOL complete) {
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.focusView.hidden = YES;
            self.exposureView.hidden = YES;
            self.focusView.transform = CGAffineTransformIdentity;
            self.exposureView.transform = CGAffineTransformIdentity;
        });
    }];
}

#pragma mark - lazy
-(UIView *)focusView{
    if (_focusView == nil) {
        _focusView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 150, 150.0f)];
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.layer.borderColor = [UIColor yellowColor].CGColor;
        _focusView.layer.borderWidth = 5.0f;
        _focusView.hidden = YES;
    }
    return _focusView;
}

@end
