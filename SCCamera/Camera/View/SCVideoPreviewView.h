//
//  SCVideoPreviewView.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/3.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCVideoPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, assign, readonly) AVCaptureVideoOrientation videoOrientation;

- (CGPoint)captureDevicePointForPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
