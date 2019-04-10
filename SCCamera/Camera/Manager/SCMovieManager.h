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

@interface SCMovieManager : NSObject

/// 视频播放方向
@property (nonatomic, assign) AVCaptureVideoOrientation referenceOrientation;

/// 当前视频方向
@property (nonatomic, assign) AVCaptureVideoOrientation currentOrientation;

@property (nonatomic, strong) AVCaptureDevice *currentDevice;

/// 开始录制
- (void)start:(void(^)(NSError *error))handle;

/// 停止录制
- (void)stop:(void(^)(NSURL *url, NSError *error))handle;

/// 写入音视频数据
- (void)writeData:(AVCaptureConnection *)connection
            video:(AVCaptureConnection*)video
            audio:(AVCaptureConnection *)audio
           buffer:(CMSampleBufferRef)buffer;

/// 保存到相册
- (void)saveMovieToCameraRoll:(NSURL *)url
                   authHandle:(void(^)(BOOL success, PHAuthorizationStatus status))authHandle
                   completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
