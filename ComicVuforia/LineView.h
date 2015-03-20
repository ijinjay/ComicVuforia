#import <UIKit/UIKit.h>

//
//  A view of a colored line between two points for displaying headpose
//
//  Created on 12/18/13.
//  Copyright (c) 2013 Sightcorp. All rights reserved.
//
@interface LineView : UIView

@property (assign) CGPoint start;
@property (assign) CGPoint end;
@property (nonatomic, retain) UIColor *color;

@end
