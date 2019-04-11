//
//  ViewController.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/2.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "ViewController.h"
#import "SCCameraController.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)openCamera:(id)sender {
    SCCameraController *cc = [SCCameraController new];
    [self presentViewController:cc animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


@end
