//
//  SCCameraController.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraController.h"
#import "SCVideoPreviewView.h"
#import "SCCameraResultController.h"
#import "SCCameraView.h"
#import "AVCaptureDevice+SCCategory.h"

#import "SCCameraManager.h"
#import "SCPhotographManager.h"

@interface SCCameraController () <SCCameraViewDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) SCCameraView *cameraView;
@property (nonatomic, strong) SCCameraManager *cameraManager;
@property (nonatomic, strong) SCPhotographManager *photographManager;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t metaQueue;
// 会话
@property (nonatomic, strong) AVCaptureSession *session;
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
@end

@implementation SCCameraController

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraManager = [SCCameraManager new];
    self.photographManager = [SCPhotographManager new];
    self.cameraView = [SCCameraView cameraView:self.view.frame];
    self.cameraView.delegate = self;
    [self.view addSubview:_cameraView];
    
    _sessionQueue = dispatch_queue_create("com.seacen.sessionQueue", DISPATCH_QUEUE_SERIAL);
    _metaQueue = dispatch_queue_create("com.seacen.metaQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(_sessionQueue, ^{
        [self configureSession:nil];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(_sessionQueue, ^{
        if (!self.session.isRunning) {
            [self.session startRunning];
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
}

#pragma mark - 会话配置
/** 配置会话 */
- (void)configureSession:(NSError**)error {
    self.session = [AVCaptureSession new];
//    _session.usesApplicationAudioSession = NO;
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    [self setupSessionInput:error];
    [self setupSessionOutput:error];
    [self.session commitConfiguration];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cameraView.previewView.captureSession = self.session;
        NSLog(@"session commit");
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
    // TODO: - 监听视频流
//    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 音频输出
    AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
    // TODO: - 监听音频流
//    [audioOut setSampleBufferDelegate:self queue:_audioQueue];
    if ([_session canAddOutput:audioOut]){
        [_session addOutput:audioOut];
    }
    _audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
    
    // 添加元素输出（识别）
    _metaOutput = [AVCaptureMetadataOutput new];
    // TODO: - 监听识别流
    if ([_session canAddOutput:_metaOutput]) {
        [_session addOutput:_metaOutput];
        // 需要先 addOutput 后面在 setMetadataObjectTypes
        [_metaOutput setMetadataObjectsDelegate:self queue:_metaQueue];
        [_metaOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    }
    
    // 静态图片输出
    _stillImageOutput = [AVCaptureStillImageOutput new];
    if ([_session canAddOutput:_stillImageOutput]) {
        [_session addOutput:_stillImageOutput];
    }
}

#pragma mark - 相机操作
/// 聚焦操作
- (void)focusAction:(SCCameraView *)cameraView point:(CGPoint)point handle:(void (^)(NSError * _Nonnull))handle {
    [self.cameraManager focus:self.currentCameraInput.device point:point handle:nil];
}

/// 曝光操作
- (void)exposAction:(SCCameraView *)cameraView point:(CGPoint)point handle:(void (^)(NSError * _Nonnull))handle {
    [self.cameraManager expose:self.currentCameraInput.device point:point handle:nil];
}

/// 转换镜头
- (void)switchCameraAction:(SCCameraView *)cameraView handle:(void (^)(NSError * _Nonnull))handle {
    
}

/// 闪光灯设置
- (void)flashLightAction:(SCCameraView *)cameraView handle:(void (^)(NSError * _Nonnull))handle {
    
}

/// 取消
- (void)cancelAction:(SCCameraView *)cameraView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 切换前后置摄像头
// FIXME: - 待定，应该在 CameraManager
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

#pragma mark - 拍照
/// 拍照
- (void)takePhotoAction:(SCCameraView *)cameraView {
    [self.photographManager takePhoto:self.cameraView.previewView.videoPreviewLayer stillImageOutput:self.stillImageOutput handle:^(UIImage * _Nonnull originImage, UIImage * _Nonnull scaledImage, UIImage * _Nonnull croppedImage) {
        NSLog(@"take photo success.");
    }];
}

#pragma mark - 录制视频
/// 开始录制视频
- (void)startRecordVideoAction:(SCCameraView *)cameraView {
    
}

/// 停止录制视频
- (void)stopRecordVideoAction:(SCCameraView *)cameraView {
    
}

#pragma mark - 方向变化处理
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        self.cameraView.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
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
    return [AVCaptureDevice cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera {
    return [AVCaptureDevice cameraWithPosition:AVCaptureDevicePositionBack];
}

@end

