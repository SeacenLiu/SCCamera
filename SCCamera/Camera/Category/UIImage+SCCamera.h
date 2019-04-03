//
//  UIImage+SCCamera.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/3.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (SCCamera)

/**
 通过抽样缓存数据创建一个UIImage对象

 @param sampleBuffer 帧数据
 @return UIImage
 */
+ (instancetype)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
