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
        
        if (face.hasRollAngle) {
            CATransform3D t = [self transformForRollAngle:face.rollAngle];
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
        
        if (face.hasYawAngle) {
            CATransform3D t = [self transformForYawAngle:face.yawAngle];
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

// Rotate around Z-axis
- (CATransform3D)transformForRollAngle:(CGFloat)rollAngleInDegrees {
    CGFloat rollAngleInRadians = THDegreesToRadians(rollAngleInDegrees);
    return CATransform3DMakeRotation(rollAngleInRadians, 0.0f, 0.0f, 1.0f);
}

// Rotate around Y-axis
- (CATransform3D)transformForYawAngle:(CGFloat)yawAngleInDegrees {
    CGFloat yawAngleInRadians = THDegreesToRadians(yawAngleInDegrees);
    
    CATransform3D yawTransform =
    CATransform3DMakeRotation(yawAngleInRadians, 0.0f, -1.0f, 0.0f);
    
    return CATransform3DConcat(yawTransform, [self orientationTransform]);
}

- (CATransform3D)orientationTransform {
    CGFloat angle = 0.0;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI / 2.0f;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI / 2.0f;
            break;
        default: // as UIDeviceOrientationPortrait
            angle = 0.0;
            break;
    }
    return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

static CGFloat THDegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

static CATransform3D CATransform3DMakePerspective(CGFloat eyePosition) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / eyePosition;
    return transform;
}

@end
