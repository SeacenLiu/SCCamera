//
//  UIViewController+SCCamera.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/4.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "UIViewController+SCCamera.h"

@implementation UIViewController (SCCamera)

- (void)showAlertView:(NSString*)message ok:(void(^)(UIAlertAction *action))ok cancel:(void(^)(UIAlertAction *action))cancel {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    if (cancel) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            !cancel ? : cancel(action) ;
        }];
        [alertController addAction:cancelAction];
    }
    if (ok) {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            !ok ? : ok(action) ;
        }];
        [alertController addAction:okAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
