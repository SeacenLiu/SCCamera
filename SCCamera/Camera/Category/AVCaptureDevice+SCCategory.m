//
//  AVCaptureDevice+SCCategory.m
//  Detector
//
//  Created by SeacenLiu on 2019/3/29.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "AVCaptureDevice+SCCategory.h"
#import <objc/runtime.h>

#pragma mark - 辅助类
@implementation SCQualityOfService

+ (instancetype)qosWithFormat:(AVCaptureDeviceFormat *)format
               frameRateRange:(AVFrameRateRange *)frameRateRange {
    
    return [[self alloc] initWithFormat:format frameRateRange:frameRateRange];
}

- (instancetype)initWithFormat:(AVCaptureDeviceFormat *)format
                frameRateRange:(AVFrameRateRange *)frameRateRange {
    self = [super init];
    if (self) {
        _format = format;
        _frameRateRange = frameRateRange;
    }
    return self;
}

/** 大于30就看成高帧率 */
- (BOOL)isHighFrameRate {
    return self.frameRateRange.maxFrameRate > 30.0f;
}

@end

#pragma mark - 分类
@implementation AVCaptureDevice (SCCategory)
@dynamic deviceQueue;

- (void)settingWithConfig:(void(^)(AVCaptureDevice* device, NSError* error))config {
    dispatch_async(self.deviceQueue, ^{
        NSError *error;
        if ([self lockForConfiguration:&error]) {
            config(self, nil);
            [self unlockForConfiguration];
        }
        if (error) {
            config(nil, error);
        }
    });
}

- (BOOL)supportsHighFrameRateCapture {
    if ([self hasMediaType:AVMediaTypeVideo] == false) {
        return NO;
    }
    return [self findHighestQualityOfService].isHighFrameRate;
}

- (SCQualityOfService*)findHighestQualityOfService {
    AVCaptureDeviceFormat *maxFormat = nil;
    AVFrameRateRange *maxFrameRateRange = nil;
    for (AVCaptureDeviceFormat *format in self.formats) {
        FourCharCode codeType = CMVideoFormatDescriptionGetCodecType(format.formatDescription);
        if (codeType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
            NSArray *frameRateRanges = format.videoSupportedFrameRateRanges;
            for (AVFrameRateRange *range in frameRateRanges) {
                if (range.maxFrameRate >  maxFrameRateRange.maxFrameRate) {
                    maxFormat = format;
                    maxFrameRateRange = range;
                }
            }
        }
    }
//    NSLog(@"%@ %@", maxFormat, maxFrameRateRange);
    return [SCQualityOfService qosWithFormat:maxFormat frameRateRange:maxFrameRateRange];
}

- (BOOL)enableMaxFrameRateCapture:(NSError **)error {
    
    SCQualityOfService *qos = [self findHighestQualityOfService];
    
    if (qos.isHighFrameRate == false) {
        if (error) {
            NSString *message = @"Device does not support high FPS capture";
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : message};
            // FIXME: - 错误码
            NSUInteger code = 1000;
            *error = [NSError errorWithDomain:@"com.seacen"
                                         code:code
                                     userInfo:userInfo];
        }
        return NO;
    }
    
    if ([self lockForConfiguration:error]) {
        CMTime minFrameDuration = qos.frameRateRange.minFrameDuration;
        
        self.activeFormat = qos.format;
        self.activeVideoMinFrameDuration = minFrameDuration;
        self.activeVideoMaxFrameDuration = minFrameDuration;
        
        [self unlockForConfiguration];
        return YES;
    }
    return NO;
}

#pragma mark - 关联对象
const char* deviceQueueKey = "com.seacen.deviceQueueKey";
- (void)setDeviceQueue:(dispatch_queue_t)deviceQueue {
    objc_setAssociatedObject(self, deviceQueueKey, deviceQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_queue_t)deviceQueue {
    dispatch_queue_t queue = objc_getAssociatedObject(self, deviceQueueKey);
    if (queue != nil) { return queue; }
    queue = dispatch_queue_create("com.seacen.device.queue", DISPATCH_QUEUE_SERIAL);
    self.deviceQueue = queue;
    return queue;
}

@end
