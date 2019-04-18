//
//  SCCameraController.h
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SCFaceDetectionDelegate <NSObject>
- (void)faceDetectionDidDetectFaces:(NSArray<AVMetadataFaceObject*>*)faces connection:(AVCaptureConnection*)connection;
@end

@interface SCCameraController : UIViewController

@property (nonatomic, weak) id<SCFaceDetectionDelegate> faceDetectionDelegate;

@end

NS_ASSUME_NONNULL_END
