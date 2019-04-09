//
//  SCCameraView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraView.h"
#import "SCVideoPreviewView.h"

@interface SCCameraView ()

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
    // 双击 -> 曝光
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exposeTabClick:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.previewView addGestureRecognizer:doubleTap];
    // 手势冲突
    [tap requireGestureRecognizerToFail:doubleTap];
}

#pragma mark - 相机操作
- (void)focusingTapClcik:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.previewView];
    CGPoint devicePoint = [self.previewView.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    if ([self.delegate respondsToSelector:@selector(focusAction:point:handle:)]) {
        [self.delegate focusAction:self point:devicePoint handle:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (void)exposeTabClick:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.previewView];
    if ([self.delegate respondsToSelector:@selector(exposAction:point:handle:)]) {
        [self.delegate exposAction:self point:point handle:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (IBAction)flashLightClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(flashLightAction:handle:)]) {
        [self.delegate flashLightAction:self handle:^(NSError * _Nonnull error) {
            
        }];
    }
}

- (IBAction)torchLightClick:(id)sender {
    
}

- (IBAction)switchCameraClick:(id)sender {
    
}

- (IBAction)cancelClick:(id)sender {
    
}

- (IBAction)takePhotoClick:(id)sender {
    
}

@end
