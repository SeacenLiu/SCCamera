//
//  SCFaceDetectionDelegate.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/19.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#ifndef SCFaceDetectionDelegate_h
#define SCFaceDetectionDelegate_h
#import <AVFoundation/AVFoundation.h>

@protocol SCFaceDetectionDelegate <NSObject>
- (void)faceDetectionDidDetectFaces:(NSArray<AVMetadataFaceObject*>*)faces connection:(AVCaptureConnection*)connection;
@end

#endif /* SCFaceDetectionDelegate_h */
