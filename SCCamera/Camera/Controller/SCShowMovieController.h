//
//  SCShowMovieController.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/26.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCShowMovieController : UIViewController

- (instancetype)initWithFileURL:(NSURL*)fileURL;

+ (instancetype)showMovieControllerWithFileURL:(NSURL*)fileURL;

@end

NS_ASSUME_NONNULL_END
