//
//  UIViewController+SCCamera.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/4.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (SCCamera)

- (void)showAlertView:(NSString*)message ok:(void(^)(UIAlertAction *action))ok cancel:(void(^)(UIAlertAction *action))cancel;

@end

NS_ASSUME_NONNULL_END
