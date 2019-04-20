//
//  SCPhotoManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/20.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^SCPhotoManagerStillImageCompletion)(UIImage *originImage, UIImage *scaledImage, UIImage *croppedImage, NSError* _Nullable error);
typedef void(^SCPhotoManagerLiveImageCompletion)(NSURL *liveURL, NSData *liveData, NSError* _Nullable error);

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(10.0))
@interface SCPhotoManager : NSObject

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;

- (instancetype)initWithPhotoOutput:(AVCapturePhotoOutput*)photoOutput;
+ (instancetype)photoManager:(AVCapturePhotoOutput*)photoOutput;

/// 静态照片拍摄
- (void)takeStillPhoto:(AVCaptureVideoPreviewLayer*)previewLayer
            completion:(SCPhotoManagerStillImageCompletion)completion;

/// 动态照片拍摄
- (void)takeLivePhoto:(AVCaptureVideoPreviewLayer*)previewLayer
           completion:(SCPhotoManagerLiveImageCompletion)completion;

@end

NS_ASSUME_NONNULL_END
