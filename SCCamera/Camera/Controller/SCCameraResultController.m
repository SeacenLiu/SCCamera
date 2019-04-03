//
//  SCCameraResultController.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/4.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCCameraResultController.h"

@interface SCCameraResultController ()
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@end

@implementation SCCameraResultController

- (IBAction)closeClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imgView.image = self.img;
}

@end
