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

#define kRevMax 0.5
#define kDisplacementMax 10

// 1fps 最高帧都是30帧 其实需要动态获取设备最高帧 再保证 1 秒 1 帧
#define kMinInterval 30

@interface SCCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput; // 后置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput; // 前置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput *currentCameraInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metaDataOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, assign) BOOL isManualFocus; // 判断是否手动对焦

@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, assign) BOOL isStartFaceRecognition;

@property (nonatomic, assign) BOOL isDetecting;
@property (nonatomic, strong) dispatch_queue_t isDectingQueue;

@property (nonatomic, strong) dispatch_queue_t videoQueue;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation SCCameraManager {
    SCStableCheckTool *stableTool;
    int minFrameDuration;
}
@synthesize isDetecting = _isDetecting;

// Test
- (void)listeningDeviceFPS {
    __weak typeof(self) weakSelf = self;
    if (@available(iOS 10.0, *)) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"-------------------------------------------");
            NSArray *inputs = weakSelf.session.inputs;
            for (AVCaptureDeviceInput* input in inputs) {
                AVCaptureDevice *device = input.device;
                AVCaptureDeviceFormat *format = device.activeFormat;
                NSArray *frameRateRanges = format.videoSupportedFrameRateRanges;
                for (AVFrameRateRange *range in frameRateRanges) {
                    NSLog(@"format: %@", format);
                    NSLog(@"range: %@", range);
                }
            }
            NSLog(@"-------------------------------------------");
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (instancetype)initWithParentView:(UIView *)parent {
    if (self = [super init]) {
        // init
        [self listeningDeviceFPS];
        stableTool = [SCStableCheckTool stableCheckToolWithRevMax:kRevMax];
        
        self.parentView = parent;
        [self.parentView addSubview:self.focusImageView];
        [self.parentView addSubview:self.faceImageView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClcik:)];
        [self.parentView addGestureRecognizer:tap];
    }
    return self;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
// 这个方法是串行同步执行的
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (self.faceRecognition) {
        for(AVMetadataObject *metadataObject in metadataObjects) {
            if([metadataObject.type isEqualToString:AVMetadataObjectTypeFace]) {
                AVMetadataObject *transform = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceImageWithFrame:transform.bounds];
                });
            }
        }
    }
}
- (void)showFaceImageWithFrame:(CGRect)rect {
    if (self.isStartFaceRecognition) {
        self.isStartFaceRecognition = NO;
        self.faceImageView.frame = rect;
        
        self.faceImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
        __weak typeof(self) weak = self;
        [UIView animateWithDuration:0.25f animations:^{
            weak.faceImageView.alpha = 1.f;
            weak.faceImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25f animations:^{
                weak.faceImageView.alpha = 0.f;
            } completion:^(BOOL finished) {
                weak.isStartFaceRecognition = YES;
            }];
        }];
    }
}

- (void)dealloc {
    [self.session stopRunning];
    [self.timer invalidate];
    NSLog(@"SCCameraManager---dealloc");
}


- (void)startUp {
    dispatch_async(self.sessionQueue, ^{
        [self->stableTool start];
        [self.session startRunning];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isStartFaceRecognition = YES;
    });
    
    [self openAutoWhiteBalance];
    self.faceRecognition = YES;
}

- (void)stop {
    dispatch_async(self.sessionQueue, ^{
        [self.session stopRunning];
        [self->stableTool stop];
    });
    self.faceRecognition = NO;
}

- (void)tapClcik:(UITapGestureRecognizer *)tap {
    CGPoint location = [tap locationInView:self.parentView];
    [self focusInPoint:location];
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
    CATransition *changeAnimation = [CATransition animation];
//    changeAnimation.delegate = self;
    changeAnimation.duration = 0.55;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionFromRight;
    changeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}

#pragma mark - 聚焦
- (void)focusInPoint:(CGPoint)devicePoint {
    if (!CGRectContainsPoint(self.previewLayer.bounds, devicePoint)) {
        return;
    }
    self.isManualFocus = YES;
    [self focusImageAnimateWithCenterPoint:devicePoint];
    devicePoint = [self.previewLayer captureDevicePointOfInterestForPoint:devicePoint];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
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
    dispatch_async(self.sessionQueue, ^{
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

// 通过抽样缓存数据创建一个UIImage对象
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    CGImageRelease(quartzImage);
    
    return (image);
}

#pragma mark - getter/setter
- (void)setParentView:(UIView *)parentView {
    _parentView = parentView;
    
    self.previewLayer.frame = parentView.bounds;
    [parentView.layer insertSublayer:self.previewLayer atIndex:0];
}

- (dispatch_queue_t)sessionQueue {
    if (!_sessionQueue) {
        _sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    }
    return _sessionQueue;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        // TODO: - 分辨率设定
        // 默认最佳像素
        // AVCaptureSessionPresetPhoto
        // AVCaptureSessionPreset1920x1080
        // AVCaptureSessionPreset1280x720 可能训练集就是这个
        // AVCaptureSessionPreset640x480
        _session.sessionPreset = AVCaptureSessionPreset1280x720;
        
        // 添加后置摄像头的输入
        if ([_session canAddInput:self.backCameraInput]) {
            [_session addInput:self.backCameraInput];
            self.currentCameraInput = self.backCameraInput;
        }
        // 添加视频输出
        if ([_session canAddOutput:self.videoDataOutput]) {
            [_session addOutput:self.videoDataOutput];
            AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection) {
                // FIXME: - 只支持竖直
//                [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                if (connection.supportsVideoStabilization) {
                    NSLog(@"isVideoStabilizationSupported");
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
            }
        }
        // 添加元素输出（识别）
        if ([_session canAddOutput:self.metaDataOutput]) {
            [_session addOutput:self.metaDataOutput];
            // 人脸识别
            [_metaDataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
            [_metaDataOutput setMetadataObjectsDelegate:self queue:self.sessionQueue];
        }
    }
    return _session;
}

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
    __weak typeof(self) weak = self;
    dispatch_async(self.sessionQueue, ^{
        [weak.session beginConfiguration];
        if (isFront) {
            [weak.session removeInput:weak.backCameraInput];
            if ([weak.session canAddInput:weak.frontCameraInput]) {
                [weak.session addInput:weak.frontCameraInput];
                weak.currentCameraInput = weak.frontCameraInput;
            }
        } else {
            [weak.session removeInput:weak.frontCameraInput];
            if ([weak.session canAddInput:weak.backCameraInput]) {
                [weak.session addInput:weak.backCameraInput];
                weak.currentCameraInput = weak.backCameraInput;
            }
        }
        [weak.session commitConfiguration];
    });
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

// 视频输出
- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setSampleBufferDelegate:self queue:self.videoQueue];
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [_videoDataOutput setVideoSettings:rgbOutputSettings];
    }
    return _videoDataOutput;
}

// 识别
- (AVCaptureMetadataOutput *)metaDataOutput {
    if (_metaDataOutput == nil) {
        _metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    }
    return _metaDataOutput;
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

#pragma mark - isDetecting
- (dispatch_queue_t)videoQueue {
    if (_videoQueue == nil) {
        _videoQueue = dispatch_queue_create("com.seacen.videoQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _videoQueue;
}

- (dispatch_queue_t)isDectingQueue {
    if (_isDectingQueue == nil) {
        _isDectingQueue = dispatch_queue_create("com.seacen.isDectQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _isDectingQueue;
}

- (void)setIsDetecting:(BOOL)isDetecting {
    dispatch_barrier_async(self.isDectingQueue, ^{
        self->_isDetecting = isDetecting;
    });
}

- (BOOL)isDetecting {
    __block BOOL tmp;
    dispatch_sync(self.isDectingQueue, ^{
        tmp = self->_isDetecting;
    });
    return tmp;
}

@end
