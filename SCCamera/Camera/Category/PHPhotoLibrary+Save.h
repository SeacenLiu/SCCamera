//
//  PHPhotoLibrary+Save.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/25.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SCPhotosSaveAuthHandle)(BOOL success, PHAuthorizationStatus status);
typedef void(^SCPhotosSaveCompletion)(BOOL success, NSError * _Nullable error);

typedef NS_ENUM(NSInteger, SCImageType) {
    SCImageTypeJPEG,
    SCImageTypePNG
};

@interface PHPhotoLibrary (Save)

/// 图片数据保存
- (void)saveImageDataToCameraRool:(NSData *)imageData
                       authHandle:(SCPhotosSaveAuthHandle)authHandle
                       completion:(SCPhotosSaveCompletion)completion;

/// 图片保存
- (void)saveImageToCameraRool:(UIImage *)image
                    imageType:(SCImageType)type
           compressionQuality:(CGFloat)quality
                   authHandle:(SCPhotosSaveAuthHandle)authHandle
                   completion:(SCPhotosSaveCompletion)completion;

/// 动态图片保存
- (void)saveLiveImageToCameraRool:(NSData *)imageData
                        shortFilm:(NSURL *)filmURL
                       authHandle:(SCPhotosSaveAuthHandle)authHandle
                       completion:(SCPhotosSaveCompletion)completion;


/// 视频保存
- (void)saveMovieFileToCameraRoll:(NSURL *)fileURL
                       authHandle:(SCPhotosSaveAuthHandle)authHandle
                       completion:(SCPhotosSaveCompletion)completion;

@end

NS_ASSUME_NONNULL_END
