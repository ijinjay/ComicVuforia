//
//  AppDelegate.h
//  ComicVuforia
//
//  Created by 靳杰 on 15/3/5.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SampleGLResourceHandler.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) id<SampleGLResourceHandler> glResourceHandler;

- (void)captureImage;

@end

