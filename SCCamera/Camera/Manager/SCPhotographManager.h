//
//  SCPhotographManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCPhotographManager : NSObject

/// 拍照
- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer stillImageOutput:(AVCaptureStillImageOutput*)stillImageOutput handle:(void (^)(UIImage *originImage, UIImage *scaledImage, UIImage *croppedImage))handle;

@end

NS_ASSUME_NONNULL_END
