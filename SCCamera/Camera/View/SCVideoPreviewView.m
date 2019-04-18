//
//  SCVideoPreviewView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/3.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCVideoPreviewView.h"

@interface SCVideoPreviewView ()
@property (nonatomic, strong) CALayer *overlayLayer;
@property (nonatomic, strong) NSMutableDictionary *faceLayers;
@end

@implementation SCVideoPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer*)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepare];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self prepare];
    }
    return self;
}

- (void)prepare {
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self setupFaceDetect];
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}

- (AVCaptureSession*)captureSession {
    return self.videoPreviewLayer.session;
}

- (void)setCaptureSession:(AVCaptureSession*)captureSession {
    self.videoPreviewLayer.session = captureSession;
    // 根据状态栏位置设置视频方向
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
    if (statusBarOrientation != UIInterfaceOrientationUnknown) {
        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
    }
    // videoPreviewLayer 也有 connection
    self.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
}

- (AVCaptureVideoOrientation)videoOrientation {
    return self.videoPreviewLayer.connection.videoOrientation;
}

#pragma mark - face detect
- (void)setupFaceDetect {
    self.faceLayers = [NSMutableDictionary dictionaryWithCapacity:2];
    self.overlayLayer = [CALayer layer];
    self.overlayLayer.frame = self.bounds;
//    CATransform3D transform = CATransform3DIdentity;
//    transform.m34 = -1.0 / 1000;
//    self.overlayLayer.sublayerTransform = transform;
    [self.videoPreviewLayer addSublayer:self.overlayLayer];
}

- (void)faceDetectionDidDetectFaces:(NSArray<AVMetadataFaceObject *> *)faces connection:(AVCaptureConnection *)connection {
    NSArray *transformedFaces = [self transformedFaces:faces];
    NSMutableArray *lostFaces = [self.faceLayers.allKeys mutableCopy];
    for (AVMetadataFaceObject *face in transformedFaces) {
        NSNumber *faceID = @(face.faceID);
        [lostFaces removeObject:faceID];
        
        CALayer *layer = self.faceLayers[faceID];
        if (!layer) {
            layer = [self makeFaceLayer];
            [self.overlayLayer addSublayer:layer];
            self.faceLayers[faceID] = layer;
        }
        layer.transform = CATransform3DIdentity;
        layer.frame = face.bounds;
    }
    for (NSNumber *faceID in lostFaces) {
        CALayer *layer = self.faceLayers[faceID];
        [layer removeFromSuperlayer];
        [self.faceLayers removeObjectForKey:faceID];
    }
}

- (CALayer*)makeFaceLayer {
    CALayer *layer = [CALayer layer];
    layer.borderWidth = 5.0f;
    layer.borderColor = [UIColor yellowColor].CGColor;
    return layer;
}

- (NSArray*)transformedFaces:(NSArray<AVMetadataFaceObject*>*)faces {
    NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:faces.count];
    for (AVMetadataFaceObject* face in faces) {
        AVMetadataObject *transfromedFace = [self.videoPreviewLayer transformedMetadataObjectForMetadataObject:face];
        [mArr addObject:transfromedFace];
    }
    return [mArr copy];
}

@end
