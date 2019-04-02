//
//  SCStableCheckTool.m
//  StaticCheckTool
//
//  Created by SeacenLiu on 2019/3/21.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCStableCheckTool.h"
#import <CoreMotion/CoreMotion.h>

@interface SCStableCheckTool ()
@property (nonatomic, strong) dispatch_queue_t stableQueue;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;
@end

@implementation SCStableCheckTool
@synthesize isStable = _isStable;

- (instancetype)init {
    if (self = [super init]) {
        _updateInterval = 1;
        _stableQueue = dispatch_queue_create("com.seacen.stableQueue", DISPATCH_QUEUE_CONCURRENT);
        _motionManager = [CMMotionManager new];
        _motionQueue = [NSOperationQueue new];
        _revMax = 0.05;
    }
    return self;
}

+ (instancetype)stableCheckToolWithRevMax:(double)revMax {
    SCStableCheckTool *tool = [[self alloc] init];
    tool.revMax = revMax;
    return tool;
}

- (void)start {
    if ([_motionManager isGyroAvailable]) {
        [_motionManager setGyroUpdateInterval:_updateInterval];
        [_motionManager startGyroUpdatesToQueue:_motionQueue withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"%@", error);
                [self.motionManager stopGyroUpdates];
                return;
            }
//            NSString *string = [NSString stringWithFormat:@"x轴转速: %.2f, y轴转速: %.2f, z轴转速: %.2f", gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z];
//            NSLog(@"%@", string);
            double rev = sqrt(gyroData.rotationRate.x*gyroData.rotationRate.x + gyroData.rotationRate.y*gyroData.rotationRate.y + gyroData.rotationRate.z*gyroData.rotationRate.z);
            BOOL flag = rev <= self.revMax;
            NSLog(@"转速向量大小: %f and %d", rev, flag);
            self.isStable = flag;
        }];
    } else {
        NSLog(@"陀螺仪不可用");
    }
}

- (void)dealloc {
    NSLog(@"SCStableCheckTool dealloc");
}

- (void)stop {
    if ([_motionManager isGyroActive]) {
        [_motionManager stopGyroUpdates];
    }
}

- (void)setIsStable:(BOOL)isStable {
    dispatch_barrier_async(self.stableQueue, ^{
        self->_isStable = isStable;
        // FIXME: - 提示手机不稳定
        if (isStable == false) {
            
        } else {
            
        }
    });
}

- (BOOL)isStable {
    __block BOOL tmp;
    dispatch_sync(self.stableQueue, ^{
        tmp = self->_isStable;
    });
    return tmp;
}

@end
