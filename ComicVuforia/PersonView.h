#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

//
//  A view of a Person object, used to display all retrieved features of a person
//
//  Created on 12/17/13.
//  Copyright (c) 2013 Sightcorp. All rights reserved.
//
class Person;
@interface PersonView : UIView

- (id)initWithFrame:(CGRect)frame
     andResourceURL:(NSURL *)url;
// Set person object |p| to be displayed
- (void)setPerson:(Person *)p;
// Get person object being displayed
- (Person *)getPerson;
// Release person object
- (void)releasePerson;
// Draw person object on |frame|. |frameCounter| is used for smoothing the
// result and |gazeView| to display eye gaze location of the person.
- (void)drawPersonWithFrameCounter:(int)frameCounter
                          andFrame:(cv::Mat &)frame
                       andGazeView:(UIView *)gazeView;

@end
