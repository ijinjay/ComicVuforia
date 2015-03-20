//
//  LineView.m
//
//  Created on 12/18/13.
//  Copyright (c) 2013 Sightcorp. All rights reserved.
//

#import "LineView.h"

@implementation LineView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
      _start = CGPointMake(0.0f, 0.0f);
      _end = CGPointMake(0.0f, 0.0f);
      _color = [UIColor whiteColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetStrokeColorWithColor(context, self.color.CGColor);
  CGContextSetLineWidth(context, 2.0);
  CGContextMoveToPoint(context, _start.x, _start.y);
  CGContextAddLineToPoint(context, _end.x, _end.y);
  CGContextStrokePath(context);
}

@end
