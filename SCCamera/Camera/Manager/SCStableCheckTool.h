//
//  SCStableCheckTool.h
//  StaticCheckTool
//
//  Created by SeacenLiu on 2019/3/21.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCStableCheckTool : NSObject

@property (nonatomic, assign) BOOL isStable;

@property (nonatomic, assign) NSTimeInterval updateInterval;

@property (nonatomic, assign) double revMax;

/** 指定构造函数 */
+ (instancetype)stableCheckToolWithRevMax:(double)revMax;

/** 需要手动开始检测 */
- (void)start;

/** 手动停止检测 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
