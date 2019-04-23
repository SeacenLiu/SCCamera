//
//  SCMovieManager.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCMovieManager : NSObject

@property (nonatomic, assign, getter=isRecording) BOOL recording;

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)startRecordWithVideoSettings:(NSDictionary*)videoSettings
                       audioSettings:(NSDictionary*)audioSettings
                              handle:(void(^_Nullable)(NSError *error))handle;

- (void)recordSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)stopRecordWithCompletion:(void(^)(BOOL success, NSURL* _Nullable fileURL))completion;

@end

NS_ASSUME_NONNULL_END
