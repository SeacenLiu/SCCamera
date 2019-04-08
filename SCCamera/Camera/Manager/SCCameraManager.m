//
//  SCCameraManager.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraManager.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+SCCamera.h"

// TODO: - 判断权限

@interface SCCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
// queue
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t videoQueue;
@property (nonatomic) dispatch_queue_t audioQueue;
@property (nonatomic) dispatch_queue_t metaQueue;
// 输入
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput *currentCameraInput;
// Connection
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
// 输出
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metaOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput; // iOS10 AVCapturePhotoOutput
// 判断是否手动对焦
@property (nonatomic, assign) BOOL isManualFocus;
// 录制
@property (nonatomic, assign, getter=isRecording) BOOL recording;

@end

@implementation SCCameraManager

#pragma mark - init
- (instancetype)init {
    if (self = [super init]) {
        // 初始化队列
        self.sessionQueue = dispatch_queue_create("com.seacen.sessionQueue", DISPATCH_QUEUE_SERIAL);
        self.videoQueue = dispatch_queue_create("com.seacen.videoQueue", DISPATCH_QUEUE_SERIAL);
        self.metaQueue = dispatch_queue_create("com.seacen.metaQueue", DISPATCH_QUEUE_SERIAL);
        self.audioQueue = dispatch_queue_create("com.seacen.audioQueue", DISPATCH_QUEUE_SERIAL);
        
        self.session = [[AVCaptureSession alloc] init];
        dispatch_async(self.sessionQueue, ^{
            NSError *error;
            [self configureSession:&error];
        });
    }
    return self;
}

- (void)dealloc {
    [self stop];
    NSLog(@"SCCameraManager dealloc");
}

- (void)startUp {
    dispatch_async(self.sessionQueue, ^{
        if (!self.session.isRunning) {
            [self.session startRunning];
        }
    });
}

- (void)stop {
    dispatch_async(self.sessionQueue, ^{
        // 预防 session 已经被释放
        if (!self.session && self.session.isRunning) {
            [self.session stopRunning];
        }
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    // 音频视频都在这里
}

#pragma mark - 配置
/** 配置会话 */
- (void)configureSession:(NSError**)error {
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    [self setupSessionInput:error];
    [self setupSessionOutput:error];
    [self.session commitConfiguration];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(cameraManagerDidLoadSession:session:)]) {
            [self.delegate cameraManagerDidLoadSession:self session:self.session];
        }
    });
}

/** 配置输入 */
- (void)setupSessionInput:(NSError**)error {
    // 视频输入(默认是后置摄像头)
    if ([_session canAddInput:self.backCameraInput]) {
        [_session addInput:self.backCameraInput];
    }
    self.currentCameraInput = _backCameraInput;
    
    // 音频输入
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:error];
    if ([_session canAddInput:audioIn]){
        [_session addInput:audioIn];
    }
}

/** 配置输出 */
- (void)setupSessionOutput:(NSError**)error {
    // 添加视频输出
    _videoOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [_videoOutput setVideoSettings:rgbOutputSettings];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 音频输出
    AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
    [audioOut setSampleBufferDelegate:self queue:self.audioQueue];
    if ([_session canAddOutput:audioOut]){
        [_session addOutput:audioOut];
    }
    _audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
    
    // 添加元素输出（识别）
    _metaOutput = [AVCaptureMetadataOutput new];
    [_metaOutput setMetadataObjectsDelegate:self queue:_metaQueue];
    if ([_session canAddOutput:_metaOutput]) {
        [_session addOutput:_metaOutput];
        [_metaOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    }
    
    // 静态图片输出
    _stillImageOutput = [AVCaptureStillImageOutput new];
    if ([_session canAddOutput:_stillImageOutput]) {
        [_session addOutput:_stillImageOutput];
    }
}

#pragma mark - 拍照操作
- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer handle:(void (^)(UIImage *, UIImage *, UIImage *))handle {
    NSLog(@"takePhoto");
    dispatch_async(self.sessionQueue, ^{
        NSLog(@"queue");
        AVCaptureConnection* stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            NSLog(@"call back");
            if (!imageDataSampleBuffer) {
                return;
            }
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *originImage = [[UIImage alloc] initWithData:imageData];
            
            CGFloat squareLength = previewLayer.bounds.size.width;
            CGFloat previewLayerH = previewLayer.bounds.size.height;
            CGFloat scale = [[UIScreen mainScreen] scale];
            CGSize size = CGSizeMake(squareLength*scale, previewLayerH*scale);
            
            // 输出 scaledImage 的时候 imageOrientation 被矫正
            UIImage *scaledImage = [originImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill size:size interpolationQuality:kCGInterpolationHigh];
            
            CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2, (scaledImage.size.height - size.height) / 2, size.width, size.height);
            UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
            
            UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
            if (orientation != UIDeviceOrientationPortrait) {
                CGFloat degree = 0;
                if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                    degree = 180; //M_PI;
                } else if (orientation == UIDeviceOrientationLandscapeLeft) {
                    degree = -90; //-M_PI_2;
                } else if (orientation == UIDeviceOrientationLandscapeRight) {
                    degree = 90; //M_PI_2;
                }
                if (self.currentCameraInput == self.frontCameraInput) {
                    degree = -degree;
                }
                croppedImage = [croppedImage rotatedByDegrees:degree];
                scaledImage = [scaledImage rotatedByDegrees:degree];
                originImage = [originImage rotatedByDegrees:degree];
            }
            // originImage.imageOrientation 是 3 代表旋转 90 度之后是正的
            // scaledImage.imageOrientation 是 0 代表当前就是正的
            originImage = [originImage fixOrientation];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handle) {
                    handle(originImage,scaledImage,croppedImage);
                }
            });
        }];
    });
}

#pragma mark - 自动白平衡
- (void)openAutoWhiteBalance {
    [self settingWithDevice:self.currentCameraInput.device config:^(AVCaptureDevice *device, NSError *error) {
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
    }];
}

#pragma mark - 闪光灯
- (void)setFlashMode:(AVCaptureFlashMode)mode {
    AVCaptureDevice *device = self.currentCameraInput.device;
    if ([device isFlashModeSupported:mode]) {
        [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            device.flashMode = mode;
        }];
    }
}

#pragma mark - 聚焦
- (void)focusInPoint:(CGPoint)devicePoint; {
    self.isManualFocus = YES;
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
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

#pragma mark - 曝光
static const NSString *CameraAdjustingExposureContext;
- (void)exposePoint:(CGPoint)point {
    [self expose:self.currentCameraInput.device point:point];
}

- (void)expose:(AVCaptureDevice *)device point:(CGPoint)point {
    BOOL supported = [device isExposurePointOfInterestSupported] &&
    [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure];
    if (supported) {
        [self settingWithDevice:device config:^(AVCaptureDevice *device, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&CameraAdjustingExposureContext];
            }
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (context == &CameraAdjustingExposureContext) {
        AVCaptureDevice *device = (AVCaptureDevice *)object;
        if (!device.isAdjustingExposure && [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [object removeObserver:self forKeyPath:@"adjustingExposure" context:&CameraAdjustingExposureContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                if ([device lockForConfiguration:&error]) {
                    device.exposureMode = AVCaptureExposureModeLocked;
                    [device unlockForConfiguration];
                } else {
                    NSLog(@"%@", error);
                }
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 切换前后置摄像头
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    dispatch_async(self.sessionQueue, ^{
        [self.session beginConfiguration];
        if (isFront) {
            [self.session removeInput:self.backCameraInput];
            if ([self.session canAddInput:self.frontCameraInput]) {
                [self.session addInput:self.frontCameraInput];
                self.currentCameraInput = self.frontCameraInput;
            }
        } else {
            [self.session removeInput:self.frontCameraInput];
            if ([self.session canAddInput:self.backCameraInput]) {
                [self.session addInput:self.backCameraInput];
                self.currentCameraInput = self.backCameraInput;
            }
        }
        [self.session commitConfiguration];
    });
}

#pragma mark - getter/setter
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

- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

#pragma mark - Tool
/** 在sessionQueue中设置Device */
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

/** 用来获取前置摄像头/后置摄像头 */
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

@end
