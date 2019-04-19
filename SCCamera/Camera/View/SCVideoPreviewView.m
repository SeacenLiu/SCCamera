//
//  SCVideoPreviewView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/3.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCVideoPreviewView.h"
#import "AVMetadataFaceObject+Transform.h"

@interface SCVideoPreviewView ()
@property (nonatomic, strong) CALayer *overlayLayer;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,CALayer*> *faceLayers;
@property (nonatomic, strong) NSMutableDictionary *faceShowes;
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
- (void)layoutSubviews {
    [super layoutSubviews];
    // 界面旋转后需要重新设置
    self.overlayLayer.frame = self.layer.frame;
    self.overlayLayer.sublayerTransform = CATransform3DMakePerspective(1000);
}

- (void)setupFaceDetect {
    self.faceLayers = [NSMutableDictionary dictionaryWithCapacity:2];
    self.overlayLayer = [CALayer layer];
    self.overlayLayer.frame = self.videoPreviewLayer.frame;
    self.overlayLayer.sublayerTransform = CATransform3DMakePerspective(1000);
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
        
        // 重置 transform
        layer.transform = CATransform3DIdentity;
        layer.frame = face.bounds;
        
        // 显示倾斜角
        if (face.hasRollAngle) {
            CATransform3D t = [face transformFromRollAngle];
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
        
        // 显示偏转角
        if (face.hasYawAngle) {
            CATransform3D t = [face transformFromYawAngle];
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
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

static CATransform3D CATransform3DMakePerspective(CGFloat eyePosition) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / eyePosition;
    return transform;
}

@end
