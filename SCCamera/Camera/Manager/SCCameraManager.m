//
//  SCCameraManager.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraManager.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+SCCameraTool.h"
#import "SCStableCheckTool.h"

@interface SCCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput; // 后置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput; // 前置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *currentCameraInput;

@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, assign) BOOL isManualFocus; // 判断是否手动对焦

@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, assign) BOOL isStartFaceRecognition;

@end

@implementation SCCameraManager {
    dispatch_queue_t _sessionQueue;
    dispatch_queue_t _videoQueue;
    dispatch_queue_t _metaQueue;
    // 会话
//    AVCaptureSession *_session;
    // 输入
    AVCaptureDeviceInput *_videoInput;
    // 输出
    AVCaptureConnection *_videoConnection;
    AVCaptureConnection *_audioConnection;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureMetadataOutput *_metaOutput;
    AVCapturePhotoOutput *_photoOutput;
    // 录制
    BOOL _recording;
}

#pragma mark - init
- (instancetype)init {
    if (self = [super init]) {
        NSError *error;
        [self setupSession:&error];
    }
    return self;
}

- (void)dealloc {
    [self stop];
    NSLog(@"SCCameraManager dealloc");
}

- (void)startUp {
//    dispatch_async(_sessionQueue, ^{
        if (!self->_session.isRunning) {
            [self->_session startRunning];
        }
//    });
}

- (void)stop {
//    dispatch_async(_sessionQueue, ^{
        if (self->_session.isRunning) {
            [self->_session stopRunning];
        }
//    });
}

#pragma mark - 配置
/** 配置会话 */
- (void)setupSession:(NSError**)error {
    // 初始化队列
    _sessionQueue = dispatch_queue_create("com.seacen.sessionQueue", DISPATCH_QUEUE_SERIAL);
    _videoQueue = dispatch_queue_create("com.seacen.videoQueue", DISPATCH_QUEUE_SERIAL);
    _metaQueue = dispatch_queue_create("com.seacen.metaQueue", DISPATCH_QUEUE_SERIAL);
    
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPresetHigh;//AVCaptureSessionPreset1280x720;
    [self setupSessionInput:error];
    [self setupSessionOutput:error];
}

/** 配置输入 */
- (void)setupSessionInput:(NSError**)error {
    // 视频输入(默认是后置摄像头)
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    if ([_session canAddInput:_videoInput]) {
        [_session addInput:_videoInput];
    }
    
    // TODO: - 音频输入
    // ...
}

/** 配置输出 */
- (void)setupSessionOutput:(NSError**)error {
    // 添加视频输出
    _videoOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [_videoOutput setVideoSettings:rgbOutputSettings];
//    [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // TODO: - 音频输出
    // ...
    
    // 添加元素输出（识别）
    _metaOutput = [AVCaptureMetadataOutput new];
    [_metaOutput setMetadataObjectsDelegate:self queue:_sessionQueue];
    if ([_session canAddOutput:_metaOutput]) {
        [_session addOutput:_metaOutput];
        [_metaOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    }
    
    // 静态图片输出
    _photoOutput = [AVCapturePhotoOutput new];
    if ([_session canAddOutput:_photoOutput]) {
        [_session addOutput:_photoOutput];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)tapClcik:(UITapGestureRecognizer *)tap {
//    CGPoint location = [tap locationInView:self.parentView];
//    [self focusInPoint:location];
}

// 开启自动白平衡
- (void)openAutoWhiteBalance {
    [self settingWithDevice:self.currentCameraInput.device config:^(AVCaptureDevice *device, NSError *error) {
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
    }];
}

// 开启闪光灯
- (void)openFlashLight {
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOff) {
        [self settingWithDevice:backCamera config:^(AVCaptureDevice *device, NSError *error) {
            device.torchMode = AVCaptureTorchModeOn;
            device.flashMode = AVCaptureFlashModeOn;
        }];
    }
}

// 关闭闪光灯
- (void)closeFlashLight {
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOn) {
        [self settingWithDevice:backCamera config:^(AVCaptureDevice *device, NSError *error) {
            device.torchMode = AVCaptureTorchModeOff;
            device.flashMode = AVCaptureTorchModeOff;
        }];
    }
}

- (void)changeCameraAnimation {
//    CATransition *changeAnimation = [CATransition animation];
////    changeAnimation.delegate = self;
//    changeAnimation.duration = 0.55;
//    changeAnimation.type = @"oglFlip";
//    changeAnimation.subtype = kCATransitionFromRight;
//    changeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}

#pragma mark - 聚焦
- (void)focusInPoint:(CGPoint)devicePoint {
//    if (!CGRectContainsPoint(self.previewLayer.bounds, devicePoint)) {
//        return;
//    }
//    self.isManualFocus = YES;
//    [self focusImageAnimateWithCenterPoint:devicePoint];
//    devicePoint = [self.previewLayer captureDevicePointOfInterestForPoint:devicePoint];
//    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusImageAnimateWithCenterPoint:(CGPoint)point {
    [self.focusImageView setCenter:point];
    self.focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
    __weak typeof(self) weak = self;
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        weak.focusImageView.alpha = 1.f;
        weak.focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            weak.focusImageView.alpha = 0.f;
        } completion:^(BOOL finished) {
            weak.isManualFocus = NO;
        }];
    }];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    [self settingWithDevice:[self.currentCameraInput device] config:^(AVCaptureDevice *device, NSError *error) {
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
            [device setFocusMode:focusMode];
            [device setFocusPointOfInterest:point];
        }
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:exposureMode];
            [device setExposurePointOfInterest:point];
        }
        [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
    }];
}

#pragma mark - Tool
- (void)settingWithDevice:(AVCaptureDevice*)device config:(void(^)(AVCaptureDevice* device, NSError* error))config {
    dispatch_async(_sessionQueue, ^{
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            config(device, nil);
            [device unlockForConfiguration];
        }
        if (error) {
            config(nil, error);
        }
    });
}

#pragma mark - getter/setter
// 后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败~");
        }
    }
    return _backCameraInput;
}

// 前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败~");
        }
    }
    return _frontCameraInput;
}
// 返回前置摄像头
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// 返回后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

// 切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    [self changeCameraAnimation];
//    __weak typeof(self) weak = self;
//    dispatch_async(self.sessionQueue, ^{
//        [weak.session beginConfiguration];
//        if (isFront) {
//            [weak.session removeInput:weak.backCameraInput];
//            if ([weak.session canAddInput:weak.frontCameraInput]) {
//                [weak.session addInput:weak.frontCameraInput];
//                weak.currentCameraInput = weak.frontCameraInput;
//            }
//        } else {
//            [weak.session removeInput:weak.frontCameraInput];
//            if ([weak.session canAddInput:weak.backCameraInput]) {
//                [weak.session addInput:weak.backCameraInput];
//                weak.currentCameraInput = weak.backCameraInput;
//            }
//        }
//        [weak.session commitConfiguration];
//    });
}

// 用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    // 返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    // 遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (UIImageView *)focusImageView {
    if (_focusImageView == nil) {
        _focusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"touch_focus"]];
        _focusImageView.alpha = 0;
    }
    return _focusImageView;
}

- (UIImageView *)faceImageView {
    if (_faceImageView == nil) {
        _faceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"face"]];
        _faceImageView.alpha = 0;
    }
    return _faceImageView;
}

@end
