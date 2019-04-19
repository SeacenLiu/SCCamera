//
//  AVMetadataFaceObject+Transform.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/19.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "AVMetadataFaceObject+Transform.h"
#import <UIKit/UIKit.h>

@implementation AVMetadataFaceObject (Transform)

// Rotate around Z-axis
- (CATransform3D)transformFromRollAngle {
    if (!self.hasRollAngle)
        return CATransform3DIdentity;
    CGFloat rollAngleInRadians = SCDegreesToRadians(self.rollAngle);
    // 绕 z 轴正方向进行旋转
    return CATransform3DMakeRotation(rollAngleInRadians, 0.0f, 0.0f, 1.0f);
}

// Rotate around Y-axis
- (CATransform3D)transformFromYawAngle {
    if (!self.hasYawAngle)
        return CATransform3DIdentity;
    CGFloat yawAngleInRadians = SCDegreesToRadians(self.yawAngle);
    // 绕 y 轴反方向进行旋转
    return CATransform3DMakeRotation(yawAngleInRadians, 0.0f, -1.0f, 0.0f);
    // 仅支持垂直界面方向
    // return CATransform3DConcat(yawTransform, [self orientationTransform]);
}

/// 仅支持HOME键在底部的二次纠正变换
- (CATransform3D)orientationTransform {
    CGFloat angle = 0.0;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI / 2.0f;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI / 2.0f;
            break;
        default: // as UIDeviceOrientationPortrait
            angle = 0.0;
            break;
    }
    // 绕 z 轴正方向进行旋转
    return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

/// 角度制转弧度制
static CGFloat SCDegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

@end
