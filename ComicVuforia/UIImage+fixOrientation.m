//
//  UIImage+fixOrientation.m
//  ComicVuforia
//
//  Created by JinJay on 15/3/23.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "UIImage+fixOrientation.h"

@implementation UIImage (fixOrientation)

- (UIImage *)fixOrientation {
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:(CGRect){0, 0, self.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

@end
