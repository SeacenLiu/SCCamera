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
#import "SCPermissionsView.h"

#import "SCCameraManager.h"
#import "SCStillPhotoManager.h"
#import "SCMovieManager.h"
#import "SCPhotoManager.h"

#import <Photos/Photos.h>

API_AVAILABLE(ios(10.0))
@interface SCCameraController () <SCCameraViewDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate,SCPermissionsViewDelegate>
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
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metaOutput;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
//@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput; // iOS10 AVCapturePhotoOutput
//@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic, strong) SCCameraView *cameraView;
@property (nonatomic, strong) SCPermissionsView *permissionsView;

@property (nonatomic, strong) SCCameraManager *cameraManager;
@property (nonatomic, strong) SCStillPhotoManager *stillPhotoManager;
@property (nonatomic, strong) SCMovieManager *movieManager;
@property (nonatomic, strong) SCPhotoManager *photoManager;

/// 有相机和麦克风的权限(必须调用getter方法)
@property (nonatomic, assign, readonly) BOOL hasAllPermissions;
@end

@implementation SCCameraController

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    if (!self.hasAllPermissions) { // 没有权限
        [self setupPermissionsView];
    } else { // 有权限
        dispatch_async(self.sessionQueue, ^{
            NSError *error;
            [self configureSession:&error];
            // TODO: - 处理配置会话错误情况
        });
    }
    self.faceDetectionDelegate = self.cameraView.previewView;
}

- (void)permissionsViewDidHasAllPermissions:(SCPermissionsView *)pv {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            pv.alpha = 0;
        } completion:^(BOOL finished) {
            [self.permissionsView removeFromSuperview];
            self.permissionsView = nil;
        }];
    });
    dispatch_async(self.sessionQueue, ^{
        [self configureSession:nil];
        [self.session startRunning];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(self.sessionQueue, ^{
        if (self.hasAllPermissions && !self.session.isRunning) {
            [self.session startRunning];
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    dispatch_async(self.sessionQueue, ^{
        if (self.session.isRunning) {
            [self.session stopRunning];
        }
    });
}

- (void)setupPermissionsView {
    [self.cameraView addSubview:self.permissionsView];
    [self.cameraView bringSubviewToFront:self.cameraView.cancelBtn];
    [self.permissionsView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.permissionsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.permissionsView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.permissionsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.permissionsView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
}

- (void)setupUI {
    [self.view addSubview:self.cameraView];
    [self.cameraView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
}

#pragma mark - 会话配置
/** 配置会话 */
- (void)configureSession:(NSError**)error {
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    [self setupSessionInput:error];
    dispatch_async(dispatch_get_main_queue(), ^{
        // 在添加视频输入后就可以设置
        self.cameraView.previewView.captureSession = self.session;
    });
    [self setupSessionOutput:error];
    [self.session commitConfiguration];
}

/** 配置输入 */
- (void)setupSessionInput:(NSError**)error {
    // 视频输入(默认是后置摄像头)
    // 创建Input时候可能会有错误
    if ([_session canAddInput:self.backCameraInput]) {
        [_session addInput:self.backCameraInput];
    }
    self.currentCameraInput = _backCameraInput;
    
    // 音频输入
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:error];
    if ([_session canAddInput:audioInput]){
        [_session addInput:audioInput];
    }
}

/** 配置输出 */
- (void)setupSessionOutput:(NSError**)error {
    // 添加视频输出
    _videoOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [_videoOutput setVideoSettings:rgbOutputSettings];
    [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // 音频输出
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    if ([_session canAddOutput:_audioOutput]){
        [_session addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    // 添加元素输出（识别）
    _metaOutput = [AVCaptureMetadataOutput new];
    if ([_session canAddOutput:_metaOutput]) {
        [_session addOutput:_metaOutput];
        // 需要先 addOutput 后面在 setMetadataObjectTypes
        [_metaOutput setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
//        [_metaOutput setMetadataObjectsDelegate:self queue:self.metaQueue];
        [_metaOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    }

    // 照片输出
    _photoOutput = [AVCapturePhotoOutput new];
    if ([_session canAddOutput:_photoOutput]) {
        [_session addOutput:_photoOutput];
        _photoOutput.highResolutionCaptureEnabled = YES;
        if (_photoOutput.livePhotoCaptureSupported) {
            _photoOutput.livePhotoCaptureEnabled = YES;
        } else {
            NSLog(@"不支持 livePhotoCaptureEnabled");
        }
    }
    
//    // 静态图片输出
//    _stillImageOutput = [AVCaptureStillImageOutput new];
//    // 设置编解码
//    _stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
//    if ([_session canAddOutput:_stillImageOutput]) {
//        [_session addOutput:_stillImageOutput];
//    }
    
    // 视频文件输出
//    _movieFileOutput = [AVCaptureMovieFileOutput new];
//    if ([_session canAddOutput:_movieFileOutput]) {
//        [_session addOutput:_movieFileOutput];
//    }
}

#pragma mark - 相机操作
/// 转换镜头
- (void)switchCameraAction:(SCCameraView *)cameraView isFront:(BOOL)isFront handle:(void(^)(NSError *error))handle {
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDeviceInput *old = isFront ? self.backCameraInput : self.frontCameraInput;
        AVCaptureDeviceInput *new = isFront ? self.frontCameraInput : self.backCameraInput;
        [self.cameraManager switchCamera:self.session old:old new:new handle:handle];
        self.currentCameraInput = new;
    });
}

/// 缩放
- (void)zoomAction:(SCCameraView *)cameraView factor:(CGFloat)factor handle:(void(^)(NSError *error))handle {
    dispatch_async(self.sessionQueue, ^{
        [self.cameraManager zoom:self.currentCameraInput.device factor:factor handle:handle];
    });
}

/// 聚焦&曝光操作
- (void)focusAndExposeAction:(SCCameraView *)cameraView point:(CGPoint)point handle:(void (^)(NSError * _Nonnull))handle {
    // instestPoint 只能在主线程获取
    CGPoint instestPoint = [cameraView.previewView captureDevicePointForPoint:point];
    dispatch_async(self.sessionQueue, ^{
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

/// 调整ISO
- (void)isoAction:(SCCameraView *)cameraView factor:(CGFloat)factor handle:(void(^)(NSError *error))handle {
    dispatch_async(self.sessionQueue, ^{
        [self.cameraManager iso:self.currentCameraInput.device factor:factor handle:handle];
    });
}

/// 重置聚焦&曝光
- (void)resetFocusAndExposeAction:(SCCameraView *)cameraView handle:(void(^)(NSError *error))handle {
    dispatch_async(self.sessionQueue, ^{
        [self.cameraManager resetFocusAndExpose:self.currentCameraInput.device handle:handle];
    });
}

/// 闪光灯
- (void)flashLightAction:(SCCameraView *)cameraView isOn:(BOOL)isOn handle:(void(^)(NSError *error))handle {
    dispatch_async(self.sessionQueue, ^{
        AVCaptureFlashMode mode = isOn?AVCaptureFlashModeOn:AVCaptureFlashModeOff;
        [self.cameraManager changeFlash:self.currentCameraInput.device mode:mode handle:handle];
    });
}

/// 补光
- (void)torchLightAction:(SCCameraView *)cameraView isOn:(BOOL)isOn handle:(void(^)(NSError *error))handle {
    dispatch_async(self.sessionQueue, ^{
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
    // 强转 AVMetadataFaceObject 
    if ([self.faceDetectionDelegate respondsToSelector:@selector(faceDetectionDidDetectFaces:connection:)]) {
        [self.faceDetectionDelegate faceDetectionDidDetectFaces:metadataObjects connection:connection];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    // SCMovieManager 的使用
//    if (self.movieManager.isRecording) {
//        [self.movieManager writeData:connection video:_videoConnection audio:_audioConnection buffer:sampleBuffer];
//    }
    if (self.movieManager.isRecording) {
        [self.movieManager processSampleBuffer:sampleBuffer];
    }
}

#pragma mark - 拍照
/// 静态拍照
- (void)takeStillPhotoAction:(SCCameraView *)cameraView {
    // photoManager 使用
    [self.photoManager takeStillPhoto:self.cameraView.previewView.videoPreviewLayer completion:^(UIImage *originImage, UIImage *scaledImage, UIImage *croppedImage, NSError * _Nullable error) {
        SCCameraResultController *rc = [SCCameraResultController new];
        rc.img = croppedImage;
        [self saveImageToCameraRoll:croppedImage];
        [self presentViewController:rc animated:YES completion:nil];
    }];
    
    /** stillPhotoManager 使用
    [self.stillPhotoManager takePhoto:self.cameraView.previewView.videoPreviewLayer stillImageOutput:self.stillImageOutput handle:^(UIImage * _Nonnull originImage, UIImage * _Nonnull scaleImage, UIImage * _Nonnull cropImage) {
        NSLog(@"take photo success.");
        // 测试用保存图片
        [self saveImageToCameraRoll:originImage];
        [self saveImageToCameraRoll:scaleImage];
        [self saveImageToCameraRoll:cropImage];

        SCCameraResultController *rc = [SCCameraResultController new];
        rc.img = cropImage;
        [self presentViewController:rc animated:YES completion:nil];
    }];
     */
}

/// 动态拍照
- (void)takeLivePhotoAction:(SCCameraView *)cameraView {
    // photoManager 使用
    [self.photoManager takeLivePhoto:self.cameraView.previewView.videoPreviewLayer completion:^(NSURL *liveURL, NSData *liveData, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//            PHAssetResourceCreationOptions* options = [[PHAssetResourceCreationOptions alloc] init];
//            options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType;
//            NSLog(@"%@",liveData);
            PHAssetCreationRequest* creationRequest = [PHAssetCreationRequest creationRequestForAsset];
            [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:liveData options:nil];
            
            PHAssetResourceCreationOptions* livePhotoCompanionMovieResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
            livePhotoCompanionMovieResourceOptions.shouldMoveFile = YES;
            [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:liveURL options:livePhotoCompanionMovieResourceOptions];
        } completionHandler:^( BOOL success, NSError * _Nullable error ) {
            if (error) {
                NSLog(@"%@", error);
                return;
            }
            NSLog(@"保存完毕");
        }];
    }];
}


/// 保存图片
- (void)saveImageToCameraRoll:(UIImage*)image {
    [self.stillPhotoManager saveImageToCameraRoll:image authHandle:^(BOOL success, PHAuthorizationStatus status) {
        
    } completion:^(BOOL success, NSError * _Nullable error) {
        
    }];
}

#pragma mark - 录制视频
/// 开始录像视频
- (void)startRecordVideoAction:(SCCameraView *)cameraView {
    // SCMovieManager 的使用
//    self.movieManager.currentDevice = self.currentCameraInput.device;
//    self.movieManager.currentOrientation = cameraView.previewView.videoOrientation;
//    [self.movieManager start:^(NSError * _Nonnull error) {
//        if (error)
//            [self.view showError:error];
//    }];
    [self.movieManager startWriting];
}

/// 停止录像视频
- (void)stopRecordVideoAction:(SCCameraView *)cameraView {
    [self.movieManager stopWriting];
    // SCMovieManager 的使用
//    [self.movieManager stop:^(NSURL * _Nonnull url, NSError * _Nonnull error) {
//        if (error) {
//            [self.view showError:error];
//        } else {
//            [self.view showAlertView:@"是否保存到相册" ok:^(UIAlertAction *act) {
//                [self saveMovieToCameraRoll: url];
//            } cancel:nil];
//        }
//    }];
}

// 保存视频
- (void)saveMovieToCameraRoll:(NSURL *)url {
    // SCMovieManager 的使用
    [self.view showLoadHUD:@"保存中..."];
//    [self.movieManager saveMovieToCameraRoll:url authHandle:^(BOOL success, PHAuthorizationStatus status) {
//        // TODO: - 权限弹框
//    } completion:^(BOOL success, NSError * _Nullable error) {
//        [self.view hideHUD];
//        success?:[self.view showError:error];
//    }];
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
- (BOOL)hasAllPermissions {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized
    && [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusAuthorized;
}

- (void)setCurrentCameraInput:(AVCaptureDeviceInput *)currentCameraInput {
    _currentCameraInput = currentCameraInput;
    [self.cameraManager whiteBalance:currentCameraInput.device mode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance handle:nil];
}

#pragma mark - lazy
// Views
- (SCCameraView *)cameraView {
    if (_cameraView == nil) {
        _cameraView = [SCCameraView cameraView:self.view.frame];
        _cameraView.delegate = self;
    }
    return _cameraView;
}

- (SCPermissionsView *)permissionsView {
    if (_permissionsView == nil) {
        _permissionsView = [[SCPermissionsView alloc] initWithFrame:self.view.bounds];
        _permissionsView.delegate = self;
    }
    return _permissionsView;
}

// Managers
- (SCCameraManager *)cameraManager {
    if (_cameraManager == nil) {
        _cameraManager = [SCCameraManager new];
    }
    return _cameraManager;
}

- (SCStillPhotoManager *)stillPhotoManager {
    if (_stillPhotoManager == nil) {
        _stillPhotoManager = [SCStillPhotoManager new];
    }
    return _stillPhotoManager;
}

- (SCMovieManager *)movieManager {
    if (_movieManager == nil) {
//        _movieManager = [SCMovieManager new];
        NSString *fileType = AVFileTypeQuickTimeMovie;
        NSDictionary *videoSettings = [self.videoOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:fileType];
        NSDictionary *audioSettings = [self.audioOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:fileType];
        _movieManager = [[SCMovieManager alloc] initWithVideoSettings:videoSettings audioSettings:audioSettings dispatchQueue:self.captureQueue];
    }
    return _movieManager;
}

- (SCPhotoManager *)photoManager  API_AVAILABLE(ios(10.0)){
    if (_photoManager == nil) {
        _photoManager = [[SCPhotoManager alloc] initWithPhotoOutput:self.photoOutput];
    }
    return _photoManager;
}

// AVFoundation
- (AVCaptureSession *)session {
    if (_session == nil) {
        _session = [AVCaptureSession new];
    }
    return _session;
}

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

// 队列懒加载
- (dispatch_queue_t)sessionQueue {
    if (_sessionQueue == NULL) {
        _sessionQueue = dispatch_queue_create("com.seacen.sessionQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _sessionQueue;
}

- (dispatch_queue_t)metaQueue {
    if (_metaQueue == NULL) {
        _metaQueue = dispatch_queue_create("com.seacen.metaQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _metaQueue;
}

- (dispatch_queue_t)captureQueue {
    if (_captureQueue == NULL) {
        _captureQueue = dispatch_queue_create("com.seacen.captureQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

@end

