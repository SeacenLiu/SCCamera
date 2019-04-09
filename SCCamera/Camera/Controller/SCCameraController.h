//
//  SCCameraController.h
//  Detector
//
//  Created by SeacenLiu on 2019/3/8.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SCCameraControllerDelegate <NSObject>



@end

@interface SCCameraController : UIViewController

@property (nonatomic, weak) id<SCCameraControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
