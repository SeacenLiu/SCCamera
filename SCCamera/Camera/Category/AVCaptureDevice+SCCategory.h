//
//  AVCaptureDevice+SCCategory.h
//  Detector
//
//  Created by SeacenLiu on 2019/3/29.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface SCQualityOfService : NSObject
@property (nonatomic, strong) AVCaptureDeviceFormat *format;
@property (nonatomic, strong) AVFrameRateRange *frameRateRange;

/** 构造函数 */
+ (instancetype)qosWithFormat:(AVCaptureDeviceFormat *)format
               frameRateRange:(AVFrameRateRange *)frameRateRange;

/** 是否支持高帧率 30fps */
- (BOOL)isHighFrameRate;

@end

@interface AVCaptureDevice (SCCategory)

/** 设备专用队列 */
@property (nonatomic, strong) dispatch_queue_t deviceQueue;

/**
 device 设置用

 @param config 配置
 @param queue 队列（NULL默认用关联的 deviceQueue）
 */
- (void)settingWithConfig:(void(^)(AVCaptureDevice* device, NSError* error))config queue:(dispatch_queue_t)queue;

/** 是否支持高帧率 30fps */ // 30 60 120
- (BOOL)supportsHighFrameRateCapture;

/** 开启f高帧率 */
- (BOOL)enableMaxFrameRateCapture:(NSError **)error;

/** 用来获取前置摄像头/后置摄像头 */
+ (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;

@end
