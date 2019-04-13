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

@class SCMovieFileOutManager;
@protocol SCMovieFileOutManagerDelegate <NSObject>

/// 完成录制
- (void)movieFileOutManagerDidFinishRecord:(SCMovieFileOutManager*)manager outputFileURL:(NSURL*)outputFileURL;

/// 错误处理
- (void)movieFileOutManagerHandleError:(SCMovieFileOutManager*)manager error:(nullable NSError*)error;

@end

/*!
 @class SCMovieFileOutManager
 @abstract
 封装 AVCaptureMovieFileOutput 的使用
 @disscussion
 需要在代理中处理完成和错误处理
 */
@interface SCMovieFileOutManager : NSObject

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, weak) id<SCMovieFileOutManagerDelegate> delegate;

/// 开始录制
- (void)start:(AVCaptureVideoOrientation)orientation;

/// 停止录制
- (void)stop;

/// 保存到相册
- (void)saveMovieToCameraRoll:(NSURL *)url
                   authHandle:(void(^)(BOOL success, PHAuthorizationStatus status))authHandle
                   completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
