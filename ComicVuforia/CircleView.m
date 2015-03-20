//
//  CircleView.m
//
//  Created on 1/3/14.
//  Copyright (c) 2014 Sightcorp. All rights reserved.
//

#import "CircleView.h"

@implementation CircleView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // default is white
    _color = [UIColor whiteColor];
    _statsFrame = CGRectZero;
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  
  CGContextSetStrokeColorWithColor(ctx, _color.CGColor);
  
  CGFloat strokeWidth = 1.0f;
  CGContextSetLineWidth(ctx, strokeWidth);
  
  CGPoint corner = _statsFrame.origin;
  CGPoint center = CGPointMake(self.bounds.size.width / 2,
                               self.bounds.size.height / 2);
  CGFloat dx = corner.x - center.x;
  CGFloat dy = corner.y - center.y;
  CGFloat radius = center.x - self.bounds.origin.x - strokeWidth;
  
  CGFloat a = asinf(dy/radius);
  CGFloat b = acosf(dx/radius);
  
  CGContextAddArc(ctx, center.x, center.y, radius,  a, b, 1);
  CGContextStrokePath(ctx);
}

@end
