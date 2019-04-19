//
//  AVMetadataFaceObject+Transform.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/19.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVMetadataFaceObject (Transform)

/**
 @abstract
    斜倾角转变换矩阵
 
 @return CATransform3D
 */
- (CATransform3D)transformFromRollAngle;

/**
 @abstract
    偏转角转变换矩阵
 @discussion
    支持屏幕多方向，若仅支持HOME键在底部的情况，需要做二次转换纠正

 @return CATransform3D
 */
- (CATransform3D)transformFromYawAngle;

@end

NS_ASSUME_NONNULL_END
