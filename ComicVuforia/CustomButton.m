//
//  CustomButton.m
//  ComicVuforia
//
//  Created by JinJay on 15/3/8.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton

- (id)initWithFrame:(CGRect)frame andTitle:(NSString *)title andBackgroundColor:(UIColor *)color andFont:(UIFont *)font {
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        [self setBackgroundColor:color];
        self.titleLabel.font = font;
    }
    return self;
}

@end