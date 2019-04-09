//
//  SCMovieManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCMovieManager : NSObject

// 视频播放方向
@property (nonatomic, assign) AVCaptureVideoOrientation referenceOrientation;

// 当前视频方向
@property (nonatomic, assign) AVCaptureVideoOrientation currentOrientation;

@property (nonatomic, strong) AVCaptureDevice *currentDevice;

- (void)start:(void(^)(NSError *error))handle;

- (void)stop:(void(^)(NSURL *url, NSError *error))handle;

- (void)writeData:(AVCaptureConnection *)connection
            video:(AVCaptureConnection*)video
            audio:(AVCaptureConnection *)audio
           buffer:(CMSampleBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
