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
           handle:(void (^)(UIImage *image))handle {
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
        dispatch_async(dispatch_get_main_queue(), ^{
            handle(originImage);
        });
    }];
}

@end
