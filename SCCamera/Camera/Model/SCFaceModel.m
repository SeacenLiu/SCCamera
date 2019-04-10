//
//  SCFaceModel.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/10.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCFaceModel.h"

@implementation SCFaceModel

- (instancetype)initWithFaceId:(NSInteger)faceId {
    if (self = [super init]) {
        self.faceId = faceId;
        self.count = 0;
    }
    return self;
}

+ (instancetype)faceModelWithFaceId:(NSInteger)faceId {
    return [[self alloc] initWithFaceId:faceId];
}

- (NSUInteger)hash {
    return self.faceId;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SCFaceModel class]]) {
        SCFaceModel *obj = (SCFaceModel*)object;
        return self.faceId == obj.faceId;
    }
    return [super isEqual:object];
}

@end
