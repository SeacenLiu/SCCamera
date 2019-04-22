//
//  SCMovieManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

// FIXME: - 录屏中切换摄像头会导致获取不了新的视频数据
/*!
 @class SCMovieManager
 @abstract
    配合 视频连接 和 音频连接 进行音视频录制 的工具类
    本类基于 AVCaptureVideoDataOutPut 因此与 AVCaptureMovieFileOutput 不可共存
    [Simultaneous AVCaptureVideoDataOutput and AVCaptureMovieFileOutput](https://stackoverflow.com/questions/3968879/simultaneous-avcapturevideodataoutput-and-avcapturemoviefileoutput)
 @discussion
    1. 设置 currentDevice 和 currentOrientation
        self.movieManager.currentDevice = self.currentCameraInput.device;
        self.movieManager.currentOrientation = cameraView.previewView.videoOrientation;
 
    2. 调用 start 方法开始录制
        [self.movieManager start:^(NSError * _Nonnull error) {
            if (error)
                [self.view showError:error];
        }];
 
    3. 在`didOutputSampleBuffer`代理方法中，调用`writeData`逐帧写入
        if (self.movieManager.isRecording) {
            [self.movieManager writeData:connection video:_videoConnection audio:_audioConnection buffer:sampleBuffer];
        }
 
    4. 调用 stop 进行停止录像
        [self.movieManager stop:^(NSURL * _Nonnull url, NSError * _Nonnull error) {
            if (error) {
                [self.view showError:error];
            } else {
                [self.view showAlertView:@"是否保存到相册" ok:^(UIAlertAction *act) {
                    [self saveMovieToCameraRoll: url];
                } cancel:nil];
            }
        }];
 */
@interface SCMovieManager : NSObject

@property (nonatomic, assign, getter=isRecording) BOOL recording;

- (instancetype)initWithVideoSettings:(NSDictionary*)videoSettings
                        audioSettings:(NSDictionary*)audioSettings
                        dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)startWriting;

- (void)stopWriting;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
