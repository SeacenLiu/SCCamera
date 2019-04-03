//
//  SCVideoPreviewView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/3.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCVideoPreviewView.h"

@implementation SCVideoPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepare];
}

- (instancetype)init {
    if (self = [super init]) {
        [self prepare];
    }
    return self;
}

- (void)prepare {
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}

- (AVCaptureVideoPreviewLayer*) videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession*)captureSession {
    return self.videoPreviewLayer.session;
}

- (void)setCaptureSession:(AVCaptureSession*)captureSession {
    self.videoPreviewLayer.session = captureSession;
}

@end
