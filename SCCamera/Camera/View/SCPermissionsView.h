//
//  SCPermissionsView.h
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/11.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCPermissionsView;
@protocol SCPermissionsViewDelegate <NSObject>
- (void)permissionsViewDidHasAllPermissions:(SCPermissionsView*)pv;
@end

NS_ASSUME_NONNULL_BEGIN

@interface SCPermissionsView : UIView
@property (nonatomic, weak) id<SCPermissionsViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
