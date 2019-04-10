//
//  SCFaceModel.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/10.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCFaceModel : NSObject
@property (nonatomic, assign) NSInteger faceId;
@property (nonatomic, assign) NSInteger count;

- (instancetype)initWithFaceId:(NSInteger)faceId;
+ (instancetype)faceModelWithFaceId:(NSInteger)faceId;
@end

NS_ASSUME_NONNULL_END
