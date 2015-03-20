//
//  BarView.m
//
//  Created on 12/10/13.
//  Copyright (c) 2013 Sightcorp. All rights reserved.
//

#import "BarView.h"

@implementation BarView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      // default is white
      _color = [UIColor whiteColor];
    }
    return self;
}


void drawGlossAndGradient(CGContextRef context,
                          CGRect rect,
                          CGColorRef startColor,
                          CGColorRef endColor) {
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGFloat locations[] = {0.0, 1.0};
  
  NSArray *colors = [NSArray arrayWithObjects:(__bridge id) startColor, (__bridge id) endColor, nil];
  
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                      (__bridge CFArrayRef) colors, locations);
  
  CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
  CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
  
  CGContextAddRect(context, rect);
  CGContextClip(context);
  CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
  
  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);
  
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  UIBezierPath *pathE = [UIBezierPath bezierPathWithRect:rect];
  CGContextSaveGState(context);
  [pathE addClip];
  
  drawGlossAndGradient(context, rect,  [UIColor whiteColor].CGColor, self.color.CGColor);
  CGContextRestoreGState(context);
}

@end
