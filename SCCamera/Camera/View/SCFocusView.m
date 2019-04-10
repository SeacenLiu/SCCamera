//
//  SCFocusView.m
//  SCCamera
//
//  Created by SeacenLiu on 2019/4/10.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCFocusView.h"

@interface SCFocusView ()
@property (nonatomic, assign) IBInspectable CGFloat lineWidth;
@end

IB_DESIGNABLE
@implementation SCFocusView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupUI];
}

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    [self setupUI];
}

- (void)drawRect:(CGRect)rect {
    CGFloat x = _lineWidth * 0.5;
    CGFloat y = x;
    CGFloat w = rect.size.width - _lineWidth;
    CGFloat h = rect.size.height - _lineWidth;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, w, h)];
    [path setLineWidth:_lineWidth];
    [path setLineCapStyle:kCGLineCapRound];
    [path setLineJoinStyle:kCGLineJoinRound];
    [[UIColor yellowColor] setStroke];
    [path stroke];
}

- (void)setupUI {
    _lineWidth = 1;
    self.backgroundColor = [UIColor clearColor];
}

@end
