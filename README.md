# SCCamera
Custom camera by AVFoundation.

- session queue problem

## Architecture
> MVC

![architecture](https://raw.githubusercontent.com/SeacenLiu/SCCamera/master/architecture.png)

## SCMovieFileOutManager 使用
```
// 创建 SCMovieFileOutManager
- (SCMovieFileOutManager *)movieFileManager {
    if (_movieFileManager == nil) {
        _movieFileManager = [SCMovieFileOutManager new];
        _movieFileManager.movieFileOutput = self.movieFileOutput;
        _movieFileManager.delegate = self;
    }
    return _movieFileManager;
}

#pragma mark - 录制视频
// 开始录像视频
- (void)startRecordVideoAction:(SCCameraView *)cameraView {
    [self.movieFileManager start:self.cameraView.previewView.videoOrientation];
}

// 停止录像视频
- (void)stopRecordVideoAction:(SCCameraView *)cameraView {
    [self.movieFileManager stop];
}

// movieFileOut 错误处理
- (void)movieFileOutManagerHandleError:(SCMovieFileOutManager *)manager error:(NSError *)error {
    [self.view showError:error];
}

// movieFileOut 录制完成处理
- (void)movieFileOutManagerDidFinishRecord:(SCMovieFileOutManager *)manager outputFileURL:(NSURL *)outputFileURL {
    // 保存视频
    [self.view showLoadHUD:@"保存中..."];
    [self.movieFileManager saveMovieToCameraRoll:outputFileURL authHandle:^(BOOL success, PHAuthorizationStatus status) {
        // TODO: - 权限处理问题
    } completion:^(BOOL success, NSError * _Nullable error) {
        [self.view hideHUD];
        success?:[self.view showError:error];
    }];
}
```

PS: `AVCaptureMovieFileOutput`不能与`AVCaptureVideoDataOutput`或`AVCaptureAudioDataOutput`共用

[Simultaneous AVCaptureVideoDataOutput and AVCaptureMovieFileOutput](https://stackoverflow.com/questions/3968879/simultaneous-avcapturevideodataoutput-and-avcapturemoviefileoutput)

