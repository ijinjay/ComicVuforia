//
//  CustomButton.m
//  ComicVuforia
//
//  Created by JinJay on 15/3/8.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "CustomButton.h"

@implementation CustomButton

- (id)initWithFrame:(CGRect)frame andImage:(NSString *)image{
    self = [super initWithFrame:frame];
    if (self) {
        [self setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end