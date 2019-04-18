//
//  SCCameraController.h
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCFaceDetectionDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface SCCameraController : UIViewController

@property (nonatomic, weak) id<SCFaceDetectionDelegate> faceDetectionDelegate;

@end

NS_ASSUME_NONNULL_END
