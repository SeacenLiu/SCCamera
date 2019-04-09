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

- (void)takePhoto:(AVCaptureVideoPreviewLayer*)previewLayer stillImageOutput:(AVCaptureStillImageOutput*)stillImageOutput handle:(void (^)(UIImage *originImage, UIImage *scaledImage, UIImage *croppedImage))handle {
    NSLog(@"takePhoto");
    AVCaptureConnection* stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        NSLog(@"call back");
        if (!imageDataSampleBuffer) {
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *originImage = [[UIImage alloc] initWithData:imageData];
        
        CGFloat squareLength = previewLayer.bounds.size.width;
        CGFloat previewLayerH = previewLayer.bounds.size.height;
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize size = CGSizeMake(squareLength*scale, previewLayerH*scale);
        
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
            // FIXME: - 前后置摄像头处理
//            if (self.currentCameraInput == self.frontCameraInput) {
//                degree = -degree;
//            }
            croppedImage = [croppedImage rotatedByDegrees:degree];
            scaledImage = [scaledImage rotatedByDegrees:degree];
            originImage = [originImage rotatedByDegrees:degree];
        }
        // originImage.imageOrientation 是 3 代表旋转 90 度之后是正的
        // scaledImage.imageOrientation 是 0 代表当前就是正的
        originImage = [originImage fixOrientation];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handle) {
                handle(originImage,scaledImage,croppedImage);
            }
        });
    }];
}

@end
