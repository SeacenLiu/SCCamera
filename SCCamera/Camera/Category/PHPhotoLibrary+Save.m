//
//  PHPhotoLibrary+Save.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/25.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "PHPhotoLibrary+Save.h"

@implementation PHPhotoLibrary (Save)

#pragma mark - still photo
+ (void)saveImageToCameraRool:(UIImage *)image
                    imageType:(SCImageType)type
             compressionQuality:(CGFloat)quality
                   authHandle:(SCPhotosSaveAuthHandle)authHandle
                   completion:(SCPhotosSaveCompletion)completion {
    NSData *data;
    switch (type) {
        case SCImageTypeJPEG:
            data = UIImageJPEGRepresentation(image, quality);
            break;
        case SCImageTypePNG:
            data = UIImagePNGRepresentation(image);
            break;
    }
    [self saveImageDataToCameraRool:data authHandle:authHandle completion:completion];
}

+ (void)saveImageDataToCameraRool:(NSData *)imageData
                   authHandle:(SCPhotosSaveAuthHandle)authHandle
                   completion:(SCPhotosSaveCompletion)completion {
    [self customSaveWithChangeBlock:^{
        PHAssetCreationRequest *imageRequest = [PHAssetCreationRequest creationRequestForAsset];
        [imageRequest addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
    } authHandle:authHandle completion:completion];
}

#pragma mark - live photo
+ (void)saveLiveImageToCameraRool:(NSData *)imageData
                        shortFilm:(NSURL *)filmURL
                       authHandle:(SCPhotosSaveAuthHandle)authHandle
                       completion:(SCPhotosSaveCompletion)completion {
    [self customSaveWithChangeBlock:^{
        PHAssetCreationRequest* creationRequest = [PHAssetCreationRequest creationRequestForAsset];
        [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
        PHAssetResourceCreationOptions* resourceOptions = [[PHAssetResourceCreationOptions alloc] init];
        resourceOptions.shouldMoveFile = YES;
        [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:filmURL options:resourceOptions];
    } authHandle:authHandle completion:completion];
}


#pragma mark - movie
+ (void)saveMovieFileToCameraRoll:(NSURL *)fileURL
                   authHandle:(SCPhotosSaveAuthHandle)authHandle
                   completion:(SCPhotosSaveCompletion)completion {
    [self customSaveWithChangeBlock:^{
        PHAssetCreationRequest *videoRequest = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions* resourceOptions = [[PHAssetResourceCreationOptions alloc] init];
        resourceOptions.shouldMoveFile = YES;
        [videoRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:resourceOptions];
    } authHandle:authHandle completion:completion];
}


#pragma mark - private
+ (void)customSaveWithChangeBlock:(dispatch_block_t)changeBlock
                        authHandle:(SCPhotosSaveAuthHandle)authHandle
                       completion:(SCPhotosSaveCompletion)completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (authHandle)
                    authHandle(false, status);
            });
            return;
        }
        [[PHPhotoLibrary sharedPhotoLibrary]
         performChanges: changeBlock
         completionHandler:^(BOOL success, NSError * _Nullable error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (completion)
                     completion(success, error);
             });
         }];
    }];
}

@end
