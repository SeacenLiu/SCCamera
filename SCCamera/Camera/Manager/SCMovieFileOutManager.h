//
//  SCMovieFileOutManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/12.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCMovieFileOutManager : NSObject

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

/// 开始录制
- (void)start:(AVCaptureVideoOrientation)orientation handle:(void(^)(NSError *error))handle;

/// 停止录制
- (void)stop:(void(^)(NSURL *url, NSError *error))handle;

/// 保存到相册
- (void)saveMovieToCameraRoll:(NSURL *)url
                   authHandle:(void(^)(BOOL success, PHAuthorizationStatus status))authHandle
                   completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
