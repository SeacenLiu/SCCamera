//
//  SCPhotographManager.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCPhotographManager.h"
#import "UIImage+SCCamera.h"

@implementation SCPhotographManager

- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer
 stillImageOutput:(AVCaptureStillImageOutput*)stillImageOutput
           handle:(void (^)(UIImage *, UIImage *, UIImage *))handle {
    NSLog(@"takePhoto");
    AVCaptureConnection* stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    NSLog(@"%@", NSStringFromCGRect(previewLayer.frame));
    stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;
    /*
     AVCaptureVideoOrientationPortrait           = 1,
     AVCaptureVideoOrientationPortraitUpsideDown = 2,
     AVCaptureVideoOrientationLandscapeRight     = 3,
     AVCaptureVideoOrientationLandscapeLeft      = 4,
     */
    NSLog(@"%ld", (long)stillImageConnection.videoOrientation);
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        NSLog(@"call back");
        if (!imageDataSampleBuffer) {
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *originImage = [[UIImage alloc] initWithData:imageData];
        /*
         // 旋转多少就变成正的 -> Home键在右边就是正的
         UIImageOrientationUp,            // default orientation
         UIImageOrientationDown,          // 180 deg rotation
         UIImageOrientationLeft,          // 90 deg CCW
         UIImageOrientationRight,         // 90 deg CW
         UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
         UIImageOrientationDownMirrored,  // horizontal flip
         UIImageOrientationLeftMirrored,  // vertical flip
         UIImageOrientationRightMirrored, // vertical flip
         */
        NSLog(@"%ld", (long)originImage.imageOrientation);
        
        CGFloat width = previewLayer.bounds.size.width;
        CGFloat height = previewLayer.bounds.size.height;
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize size = CGSizeMake(width*scale, height*scale);
        
        // 输出 scaledImage 的时候 imageOrientation 被矫正
        UIImage *scaledImage = [originImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill size:size interpolationQuality:kCGInterpolationHigh];
        
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2, (scaledImage.size.height - size.height) / 2, size.width, size.height);
        UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation != UIDeviceOrientationPortrait) {
            CGFloat degree = 0;
            if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                degree = 180; //M_PI;
            } else if (orientation == UIDeviceOrientationLandscapeLeft) {
                degree = -90; //-M_PI_2;
            } else if (orientation == UIDeviceOrientationLandscapeRight) {
                degree = 90; //M_PI_2;
            }
            croppedImage = [croppedImage rotatedByDegrees:degree];
            scaledImage = [scaledImage rotatedByDegrees:degree];
            originImage = [originImage rotatedByDegrees:degree];
        }
        originImage = [originImage fixOrientation];
        dispatch_async(dispatch_get_main_queue(), ^{
            handle(croppedImage, scaledImage, croppedImage);
        });
        // TODO: - 需要裁剪成和预览图效果一致
    }];
}

- (void)saveImageToCameraRoll:(UIImage*)image
                   authHandle:(void(^)(BOOL success, PHAuthorizationStatus status))authHandle
                   completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if (status != PHAuthorizationStatusAuthorized) {
            authHandle(false, status);
            return;
        }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCreationRequest *imageRequest = [PHAssetCreationRequest creationRequestForAsset];
            [imageRequest addResourceWithType:PHAssetResourceTypePhoto data:UIImagePNGRepresentation(image) options:nil];
        } completionHandler:^( BOOL success, NSError * _Nullable error ) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }];
    }];
}

@end
