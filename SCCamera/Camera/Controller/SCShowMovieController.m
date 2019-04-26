//
//  SCShowMovieController.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/26.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCShowMovieController.h"
#import <AVKit/AVKit.h>

@interface SCShowMovieController ()
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) AVPlayerViewController *playerController;
@end

@implementation SCShowMovieController

- (instancetype)initWithFileURL:(NSURL*)fileURL {
    if (self = [super init]) {
        self.fileURL = fileURL;
    }
    return self;
}

+ (instancetype)showMovieControllerWithFileURL:(NSURL*)fileURL {
    return [[self alloc] initWithFileURL:fileURL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playerController = [[AVPlayerViewController alloc] init];
    self.playerController.player = [AVPlayer playerWithURL:self.fileURL];
    self.playerController.view.frame = self.view.frame;
    [self.view addSubview:self.playerController.view];
}

@end
