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
#import "UIView+CCHUD.h"
#import <Photos/Photos.h>
#import "SCFocusView.h"
#import "SCFaceModel.h"

#import "SCCameraManager.h"
#import "SCPhotographManager.h"
#import "SCMovieManager.h"

@interface SCCameraController () <SCCameraViewDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t metaQueue;
@property (nonatomic) dispatch_queue_t captureQueue;
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

@property (nonatomic, strong) SCCameraView *cameraView;
@property (nonatomic, strong) SCCameraManager *cameraManager;
@property (nonatomic, strong) SCPhotographManager *photographManager;
@property (nonatomic, strong) SCMovieManager *movieManager;

@property (nonatomic, assign) BOOL recording;

// 用于人脸检测显示
/// 需要使用 NSCache
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, SCFaceModel*> *faceModels;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, SCFocusView*> *faceFocusViews;
@end

@implementation SCCameraController

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraView = [SCCameraView cameraView:self.view.frame];
    self.cameraView.delegate = self;
    
    [self.view addSubview:_cameraView];
    [self.cameraView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    
    self.cameraManager = [SCCameraManager new];
    self.photographManager = [SCPhotographManager new];
    self.movieManager = [SCMovieManager new];
    
    _sessionQueue = dispatch_queue_create("com.seacen.sessionQueue", DISPATCH_QUEUE_SERIAL);
    _metaQueue = dispatch_queue_create("com.seacen.metaQueue", DISPATCH_QUEUE_SERIAL);
    _captureQueue = dispatch_queue_create("com.seacen.captureQueue", DISPATCH_QUEUE_SERIAL);
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

#pragma mark - 会话配置
/** 配置会话 */
- (void)configureSession:(NSError**)error {
    self.session = [AVCaptureSession new];
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
    [_videoOutput setSampleBufferDelegate:self queue:_captureQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 音频输出
    AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
    // TODO: - 监听音频流
    [audioOut setSampleBufferDelegate:self queue:_captureQueue];
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
/// 缩放
- (void)zoomAction:(SCCameraView *)cameraView factor:(CGFloat)factor handle:(void(^)(NSError *error))handle {
    dispatch_async(_sessionQueue, ^{
        [self.cameraManager zoom:self.currentCameraInput.device factor:factor handle:handle];
    });
}

/// 聚焦&曝光操作
- (void)focusAndExposeAction:(SCCameraView *)cameraView point:(CGPoint)point handle:(void (^)(NSError * _Nonnull))handle {
    // instestPoint 只能在主线程获取
    CGPoint instestPoint = [cameraView.previewView captureDevicePointForPoint:point];
    dispatch_async(_sessionQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [cameraView runFocusAnimation:point];
        });
        [self.cameraManager focusWithMode:AVCaptureFocusModeAutoFocus
                           exposeWithMode:AVCaptureExposureModeAutoExpose
                                   device:self.currentCameraInput.device
                            atDevicePoint:instestPoint
                 monitorSubjectAreaChange:YES
                                   handle:handle];
    });
}

/// 转换镜头
- (void)switchCameraAction:(SCCameraView *)cameraView isFront:(BOOL)isFront handle:(void(^)(NSError *error))handle {
    dispatch_async(_sessionQueue, ^{
        AVCaptureDeviceInput *old = isFront ? self.backCameraInput : self.frontCameraInput;
        AVCaptureDeviceInput *new = isFront ? self.frontCameraInput : self.backCameraInput;
        [self.cameraManager switchCamera:self.session old:old new:new handle:handle];
    });
}

/// 闪光灯
- (void)flashLightAction:(SCCameraView *)cameraView isOn:(BOOL)isOn handle:(void(^)(NSError *error))handle {
    dispatch_async(_sessionQueue, ^{
        AVCaptureFlashMode mode = isOn?AVCaptureFlashModeOn:AVCaptureFlashModeOff;
        [self.cameraManager changeFlash:self.currentCameraInput.device mode:mode handle:handle];
    });
}

/// 补光
- (void)torchLightAction:(SCCameraView *)cameraView isOn:(BOOL)isOn handle:(void(^)(NSError *error))handle {
    dispatch_async(_sessionQueue, ^{
        AVCaptureTorchMode mode = isOn?AVCaptureTorchModeOn:AVCaptureTorchModeOff;
        [self.cameraManager changeTorch:self.currentCameraInput.device mode:mode handle:handle];
    });
}

/// 取消
- (void)cancelAction:(SCCameraView *)cameraView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    for (AVMetadataObject *metadataObject in metadataObjects) {
        if ([metadataObject isKindOfClass:[AVMetadataFaceObject class]]) {
            AVMetadataFaceObject *faceObject = (AVMetadataFaceObject*)metadataObject;
            NSLog(@"--------------- faceObject ---------------");
            [self testLogCMTime:faceObject.time str:@"time"];
            [self testLogCMTime:faceObject.duration str:@"duration"];
            NSLog(@"bounds: %@", NSStringFromCGRect(faceObject.bounds));
            NSLog(@"type: %@", faceObject.type);
            NSLog(@"faceID: %ld", (long)faceObject.faceID);
            NSLog(@"hasRollAngle: %d", faceObject.hasRollAngle);
            NSLog(@"rollAngle: %f", faceObject.rollAngle);
            NSLog(@"hasYawAngle: %d", faceObject.hasYawAngle);
            NSLog(@"yawAngle: %f", faceObject.yawAngle);
            NSLog(@"--------------- ---------- ---------------");
            // 框人脸
            dispatch_async(dispatch_get_main_queue(), ^{
                AVMetadataObject *face = [self.cameraView.previewView.videoPreviewLayer transformedMetadataObjectForMetadataObject:faceObject];
                NSInteger faceId = faceObject.faceID;
                NSNumber *faceIdNum = [NSNumber numberWithInteger:faceId];
                
                SCFaceModel *model = self.faceModels[faceIdNum];
                if (model == nil) {
                    // 不存在的话 就创建对象立即退出
                    model = [SCFaceModel faceModelWithFaceId:faceId];
                    self.faceModels[faceIdNum] = model;
                    return;
                }
                model.count += 1;
                if (model.count > 100) {
                    // 已经显示够了 需要移除
                    SCFocusView *focusView = self.faceFocusViews[faceIdNum];
                    [focusView removeFromSuperview];
                    [self.faceFocusViews removeObjectForKey:faceIdNum];
                    return;
                }
                
                CGRect focusRect = face.bounds;
                SCFocusView *focusView = self.faceFocusViews[faceIdNum];
                if (focusView == nil) {
                    focusView = [[SCFocusView alloc] initWithFrame:focusRect];
                    self.faceFocusViews[faceIdNum] = focusView;
                    [self.cameraView.previewView addSubview:focusView];
                } else {
                    focusView.frame = focusRect;
                    NSInteger cur = model.count;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (cur == model.count) {
                            [focusView removeFromSuperview];
                            [self.faceFocusViews removeObjectForKey:faceIdNum];
                        }
                    });
                }
            });
        }
    }
}

- (void)testLogCMTime:(CMTime)time str:(NSString*)str {
    NSLog(@"%@:", str);
    NSLog(@"value: %lld", time.value);
    NSLog(@"timescale: %d", time.timescale);
    NSLog(@"flags: %u", time.flags);
    NSLog(@"epoch: %lld", time.epoch);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (_recording) {
        [_movieManager writeData:connection video:_videoConnection audio:_audioConnection buffer:sampleBuffer];
    }
}

#pragma mark - 拍照
/// 拍照
- (void)takePhotoAction:(SCCameraView *)cameraView {
    [self.photographManager takePhoto:self.cameraView.previewView.videoPreviewLayer stillImageOutput:self.stillImageOutput handle:^(UIImage * _Nonnull originImage, UIImage * _Nonnull scaleImage, UIImage * _Nonnull cropImage) {
        NSLog(@"take photo success.");
        // 测试用保存图片
        [self saveImageToCameraRoll:cropImage];
        
        SCCameraResultController *rc = [SCCameraResultController new];
        rc.img = cropImage;
        [self presentViewController:rc animated:YES completion:nil];
    }];
}

/// 保存图片
- (void)saveImageToCameraRoll:(UIImage*)image {
    [self.photographManager saveImageToCameraRoll:image authHandle:^(BOOL success, PHAuthorizationStatus status) {
        
    } completion:^(BOOL success, NSError * _Nullable error) {
        
    }];
}

#pragma mark - 录制视频
/// 开始录像视频
- (void)startRecordVideoAction:(SCCameraView *)cameraView{
    _recording = YES;
    _movieManager.currentDevice = self.currentCameraInput.device;
    _movieManager.currentOrientation = cameraView.previewView.videoOrientation;
    [_movieManager start:^(NSError * _Nonnull error) {
        if (error)
            [self.view showError:error];
    }];
}

/// 停止录像视频
- (void)stopRecordVideoAction:(SCCameraView *)cameraView{
    _recording = NO;
    [_movieManager stop:^(NSURL * _Nonnull url, NSError * _Nonnull error) {
        if (error) {
            [self.view showError:error];
        } else {
            [self.view showAlertView:@"是否保存到相册" ok:^(UIAlertAction *act) {
                [self saveMovieToCameraRoll: url];
            } cancel:nil];
        }
    }];
}

// 保存视频
- (void)saveMovieToCameraRoll:(NSURL *)url{
    [self.view showLoadHUD:@"保存中..."];
    [self.movieManager saveMovieToCameraRoll:url authHandle:^(BOOL success, PHAuthorizationStatus status) {
        // TODO: - 权限弹框
    } completion:^(BOOL success, NSError * _Nullable error) {
        [self.view hideHUD];
        success?:[self.view showError:error];
    }];
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

- (NSMutableDictionary<NSNumber *,SCFaceModel *> *)faceModels {
    if (_faceModels == nil) {
        _faceModels = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    return _faceModels;
}

- (NSMutableDictionary<NSNumber *,SCFocusView *> *)faceFocusViews {
    if (_faceFocusViews == nil) {
        _faceFocusViews = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    return _faceFocusViews;
}

@end

