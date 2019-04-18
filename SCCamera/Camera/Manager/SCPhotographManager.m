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
    AVCaptureConnection* stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation videoOrientation = previewLayer.connection.videoOrientation;
    if (stillImageConnection.supportsVideoOrientation) {
        stillImageConnection.videoOrientation = videoOrientation;
    }
    void (^completionHandler)(CMSampleBufferRef, NSError *) = ^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error){
        if (!imageDataSampleBuffer) {
            return;
        }
        // 1. 获取 originImage
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *originImage = [[UIImage alloc] initWithData:imageData];
        originImage = [originImage fixOrientation];
        // 2. 获取 scaledImage
        CGFloat width = previewLayer.bounds.size.width;
        CGFloat height = previewLayer.bounds.size.height;
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize size = CGSizeMake(width*scale, height*scale);
        UIImage *scaledImage = [originImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill size:size interpolationQuality:kCGInterpolationHigh];
        // 3. 获取 croppedImage
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) * 0.5, (scaledImage.size.height - size.height) * 0.5, size.width, size.height);
        UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
        // 4. 回调
        dispatch_async(dispatch_get_main_queue(), ^{
            handle(originImage, scaledImage, croppedImage);
        });
    };
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler: completionHandler];
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
