//
//  SCPhotographManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCPhotographManager : NSObject

/// 拍照
- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer
 stillImageOutput:(AVCaptureStillImageOutput*)stillImageOutput
           handle:(void (^)(UIImage *originImage, UIImage *scaledImage, UIImage *croppedImage))handle;

/// 保存到相册
- (void)saveImageToCameraRoll:(UIImage*)image
                   authHandle:(void(^)(BOOL success, PHAuthorizationStatus status))authHandle
                   completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
