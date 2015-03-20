//
//  PersonView.m
//
//  Created on 12/17/13.
//  Copyright (c) 2013 Sightcorp. All rights reserved.
//

#import "PersonView.h"
#import "BarView.h"
#import "LineView.h"
#import "CircleView.h"
#import <insight/insight.h>

@implementation PersonView {
  __weak UIImageView *_detectionView1;
  __weak UIImageView *_detectionView2;
  __weak UIImageView *_statsBkgView;
  
  __weak CircleView *_circleView;
  
  __weak UILabel *_ID;
  __weak UILabel *_attention;
  __weak UILabel *_age;
  __weak UILabel *_gender;
  
  __weak BarView *_neutralView;
  __weak BarView *_happyView;
  __weak BarView *_surpriseView;
  __weak BarView *_angerView;
  __weak BarView *_disgustedView;
  __weak BarView *_fearView;
  __weak BarView *_sadnessView;
  
  __weak LineView *_headPose;
  
  Person *_person;
}

// Init constants
cv::Scalar KCOLOR_BLUE_1   = cv::Scalar( 0xe4, 0X5a, 0X5a );
cv::Scalar KCOLOR_GREEN_1  = cv::Scalar( 0x10, 0xaa, 0x10 );
cv::Scalar KCOLOR_ORANGE_1 = cv::Scalar( 0x00, 0x7f, 0xff );
cv::Scalar KCOLOR_WHITE_1  = cv::Scalar( 0xff, 0xff, 0xff );
cv::Scalar KCOLOR_BLACK_1  = cv::Scalar( 0x00, 0x00, 0x00 );

cv::Scalar KCOLOR_GREEN_2  = cv::Scalar( 0x00, 0xff, 0x00 );
cv::Scalar KCOLOR_BLUE_2   = cv::Scalar( 0xe4, 0X5a, 0X5a );
cv::Scalar KCOLOR_RED_1    = cv::Scalar( 0x00, 0x00, 0xff );
cv::Scalar KCOLOR_YELLOW_1 = cv::Scalar( 0x00, 0xff, 0xff );
cv::Scalar KCOLOR_BROWN_1  = cv::Scalar( 0x00, 0x40, 0xa0 );
cv::Scalar KCOLOR_PURPLE_1 = cv::Scalar( 0xc8, 0x00, 0xc8 );

cv::Scalar KCOLOR_BLUE_3   = cv::Scalar( 0xa0, 0x74, 0x05 );

cv::Scalar KCOLOR_GRAY_1   = cv::Scalar( 0xc0, 0xc0, 0xc0 );


cv::Point KPOINT_OFFSET_ID        = cv::Point( 60, -19 );
cv::Point KPOINT_OFFSET_ATTENTION = cv::Point( 60, -2 );
cv::Point KPOINT_OFFSET_AGE       = cv::Point( 60, 15 );
cv::Point KPOINT_OFFSET_GENDER    = cv::Point( 60, 32 );

cv::Point KPOINT_OFFSET_EMOTION_BAR_NEUTRAL   = cv::Point( 120, 32 );
cv::Point KPOINT_OFFSET_EMOTION_BAR_HAPPY     = cv::Point( 120, 55 );
cv::Point KPOINT_OFFSET_EMOTION_BAR_SURPRISE  = cv::Point( 120, 78 );
cv::Point KPOINT_OFFSET_EMOTION_BAR_ANGER     = cv::Point( 120, 100 );
cv::Point KPOINT_OFFSET_EMOTION_BAR_DISGUSTED = cv::Point( 120, 123 );
cv::Point KPOINT_OFFSET_EMOTION_BAR_FEAR      = cv::Point( 120, 146 );
cv::Point KPOINT_OFFSET_EMOTION_BAR_SADNESS   = cv::Point( 120, 169 );

std::vector<std::list<float> > emotions;
static std::map<std::string, std::list<Person> > personHistory;

CGFloat _scale;


- (id)initWithFrame:(CGRect)frame
     andResourceURL:(NSURL *)url {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    _person = NULL;
    // Load overlay images
    _detectionView1 = [self imageViewFromImage:@"detection1.png" atURL:url];
    _detectionView2 = [self imageViewFromImage:@"detection2.png" atURL:url];
    _statsBkgView   = [self imageViewFromImage:@"stats_bkg.png" atURL:url];
    
    // Load face circle
    _circleView     = [self loadCircleView];
    
    // Load text labels
    _ID            = [self loadLabel];
    _attention     = [self loadLabel];
    _age           = [self loadLabel];
    _gender        = [self loadLabel];
    
    // Load emotion bars
    _neutralView   = [self loadBarView];
    _happyView     = [self loadBarView];
    _surpriseView  = [self loadBarView];
    _angerView     = [self loadBarView];
    _disgustedView = [self loadBarView];
    _fearView      = [self loadBarView];
    _sadnessView   = [self loadBarView];
    
    // Load headpose pointer
    _headPose      = [self loadLine];
    
    // Setup drawing scale for UIView
    CGFloat xscale = ( self.bounds.size.width / 640.0f );
    CGFloat yscale = ( self.bounds.size.height / 480.0f );
    _scale = MAX(xscale, yscale);
  }
  return self;
}


#pragma mark - Init functions

- (UIImageView *)imageViewFromImage:(NSString *)imageName atURL:(NSURL *)url {
  NSURL *imageUrl =
  [url URLByAppendingPathComponent:imageName];
  UIImage *image = [UIImage imageWithContentsOfFile:imageUrl.path];
  
  UIImageView *view = [[UIImageView alloc] initWithImage:image];
  view.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
  
  //  view.clipsToBounds = YES;
  //  view.layer.anchorPoint = CGPointMake(0.5, 0.5);
  view.alpha = 0.0f;
  
  [self addSubview:view];
  return view;
}

-(CircleView *)loadCircleView {
  
  CircleView *view = [[CircleView alloc] initWithFrame:self.bounds];
  view.clipsToBounds = NO;
  //  view.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
  view.alpha = 0.0f;
  view.opaque = NO;
  
  [self addSubview:view];
  return view;
}

-(BarView *)loadBarView {
  
  BarView *view = [[BarView alloc]
                   initWithFrame:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f)];
  //  view.clipsToBounds = YES;
  //  view.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
  view.alpha = 0.0f;
  
  [self addSubview:view];
  return view;
}

-(UILabel *)loadLabel {
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f)];
  
  [label setTextColor:[UIColor blackColor]];
  [label setBackgroundColor:[UIColor clearColor]];
  [label setFont:[UIFont fontWithName: @"Trebuchet MS" size: 7.0f]];
  [self addSubview:label];
  return label;
}

-(LineView *)loadLine {
  LineView *l = [[LineView alloc] initWithFrame:self.bounds];
  l.alpha = 0.0f;
  l.opaque = NO;
  [self addSubview:l];
  return l;
}

#pragma mark - Drawing functions

- (void)overlayRect:(CGRect)rect
           withView:(UIView *)view
          withAngle:(CGFloat)angle {
  // Make view visible in case it was hidden
  view.alpha = 1.0f;
  
  // Move anchor point to center for rotation
  CGPoint originalAnchor = view.layer.anchorPoint;
  view.layer.anchorPoint = CGPointMake(0.5, 0.5);
  
  CGFloat x = rect.origin.x * _scale;
  CGFloat y = rect.origin.y * _scale;
  CGFloat width  = rect.size.width * _scale;
  CGFloat height = rect.size.height * _scale;
  
  // Overlay face
  [UIView animateWithDuration:0.4 animations:^{
    
    // Translate
    view.center = CGPointMake(x + width/2, y + height/2);
    // Rotate around center
    view.transform = CGAffineTransformMakeRotation(M_PI/180 * angle);
    // Scale
    view.bounds = CGRectMake(0.0f, 0.0f, width, height);
    
  }];
  
  // Set anchor point to original value
  view.layer.anchorPoint = originalAnchor;
}

- (void)overlayPoint:(CGPoint)point
            withView:(UIView *)view {
  
  // Make view visible in case it was hidden
  view.alpha = 1.0f;
  
  CGFloat x = point.x * _scale;
  CGFloat y = point.y * _scale;
  
  // Overlay face
  [UIView animateWithDuration:0.4 animations:^{
    
    // Translate
    view.transform = CGAffineTransformMakeTranslation(x, y);
    
  }];
  
  //  // Set anchor point to original value
  //  view.layer.anchorPoint = originalAnchor;
  
}

- (void)overlayRect:(CGRect)rect
     withCircleView:(CircleView *)view
     withStatsFrame:(CGRect)f
          withColor:(UIColor *)c {
  // Make view visible in case it was hidden
  view.alpha = 1.0f;
  
  view.color = c;
  
  view.statsFrame = CGRectMake((f.origin.x - rect.origin.x) * _scale,
                               (f.origin.y - rect.origin.y) * _scale,
                               f.size.width,
                               f.size.height);
  
  [view setNeedsDisplay];
  [self overlayRect:rect withView:view withAngle:0.0f];
}

- (void)overlayRect:(CGRect)rect
        withBarView:(BarView *)barView
          withColor:(UIColor *)c {
  // Make view visible in case it was hidden
  barView.alpha = 1.0f;
  
  barView.color = c;
  [barView setNeedsDisplay];
  [self overlayRect:rect withView:barView withAngle:0.0f];
}

- (void)overlayRect:(CGRect)rect
       withLineView:(LineView *)lineView
          withColor:(UIColor *)c {
  // Make view visible in case it was hidden
  lineView.alpha = 1.0f;
  
  lineView.color = c;
  [lineView setNeedsDisplay];
  [self overlayRect:rect withView:lineView withAngle:0.0f];
}


// iOS overlay face with image
#define overlayRect(a, b, c) ovl(a, b, c, self)
void ovl( cv::Rect face,
         UIImageView *view,
         double angle,
         id obj ) {
  CGRect r = CGRectMake(face.x, face.y, face.width, face.height);
  dispatch_async(dispatch_get_main_queue(), ^{
    [obj overlayRect:r withView:view withAngle:angle];
  });
}


// iOS overlay point with image
#define overlayPoint(a, b) ovl(a, b, self)
void ovl( cv::Point point,
         UIImageView *view,
         id obj ) {
  CGPoint p = CGPointMake(point.x, point.y);
  dispatch_async(dispatch_get_main_queue(), ^{
    [obj overlayPoint:p withView:view];
  });
}

// iOS overlay point with circle
#define drawCircle(a, b, c, d) dcr(a, b, c, d, self)
void dcr( cv::Rect face,
         CircleView *view,
         cv::Rect statsFrame,
         cv::Scalar color,
         id obj ) {
  CGRect r = CGRectMake(face.x, face.y, face.width, face.height);
  CGRect f = CGRectMake(statsFrame.x, statsFrame.y, statsFrame.width, statsFrame.height);
  UIColor *c = [UIColor colorWithRed:color[2]/255.0f
                               green:color[1]/255.0f
                                blue:color[0]/255.0f
                               alpha:1.0f];
  dispatch_async(dispatch_get_main_queue(), ^{
    [obj overlayRect:r
      withCircleView:view
      withStatsFrame:f
           withColor:c];
  });
}

// iOS overlay point with image
#define drawBar(a, b, c, d) dbr(a, b, c, d, self)
void dbr( cv::Point point1,
         cv::Point point2,
         BarView *barView,
         cv::Scalar color,
         id obj ) {
  CGRect r = CGRectMake(point1.x, point1.y,
                        point2.x - point1.x,
                        point2.y - point1.y);
  UIColor *c = [UIColor colorWithRed:color[2]/255.0f
                               green:color[1]/255.0f
                                blue:color[0]/255.0f
                               alpha:1.0f];
  dispatch_async(dispatch_get_main_queue(), ^{
    [obj overlayRect:r withBarView:barView withColor:c];
  });
}

// iOS drawText
#define drawText(a, b, c, d) dbt(a, b, c, d, self)
void dbt( cv::Point point1,
         cv::Point point2,
         UILabel *label,
         std::string & text,
         id obj ) {
  CGRect r = CGRectMake(point1.x, point1.y,
                        point2.x - point1.x,
                        point2.y - point1.y);
  dispatch_sync(dispatch_get_main_queue(), ^{
    
    // Set label text
    [label setText:[NSString stringWithCString:text.c_str()
                                      encoding:[NSString defaultCStringEncoding]]];
    
    [obj overlayRect:r withView:label withAngle:0.0f];
  });
}

// iOS drawLine
#define drawLine(a, b, c, d) dbl(a, b, c, d, self)
void dbl( cv::Point point1,
         cv::Point point2,
         LineView *line,
         cv::Scalar color,
         id obj ) {
  CGPoint a = CGPointMake(point1.x * _scale, point1.y * _scale);
  CGPoint b = CGPointMake(point2.x * _scale, point2.y * _scale);
  
  UIColor *c = [UIColor colorWithRed:color[2]/255.0f
                               green:color[1]/255.0f
                                blue:color[0]/255.0f
                               alpha:1.0f];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    // Make view visible in case it was hidden
    line.alpha = 1.0f;
    line.color = c;
    line.start = a;
    line.end = b;
    [line setNeedsDisplay];
  });
}

// iOS drawLine
#define drawEyeGaze(a,b) deg(a, b, self)
void deg( cv::Point gaze,
          UIView * view,
          id obj ) {
  dispatch_async(dispatch_get_main_queue(), ^{
    // Make view visible in case it was hidden
    view.hidden = FALSE;
    [UIView animateWithDuration:0.2 animations:^{
      
      // Translate
      view.transform = CGAffineTransformMakeTranslation(gaze.x, gaze.y);
      
    }];
  });
}


- (void)drawPersonWithFrameCounter:(int)frameCounter andFrame:(cv::Mat &)frame andGazeView:(UIView *)gazeView {
  // Retrieve current person
  Person person  = *_person;
  std::string ID = person.getID();
  cv::Rect face;
  
  cv::Size  faceSize( 0, 0 );
  cv::Point facePosition( 0, 0 );
  cv::Point leftEyePosition( 0, 0 );
  cv::Point rightEyePosition( 0, 0 );
  cv::Point eyeGaze( 0, 0 );
  float     yaw = 0.0f, pitch = 0.0f;
  float     neutral = 0.0f, happy = 0.0f, surprise = 0.0f, anger = 0.0f, disgusted = 0.0f, fear = 0.0f, sadness = 0.0f;
  float     mood = 0.0f;
  
  // Smooth with previous 3 frames
  personHistory[ID].push_back( person );
  if ( personHistory[ID].size() > 3 )
    personHistory[ID].pop_front();
  std::list<Person>::iterator it = personHistory[ID].begin();
  for ( ; it != personHistory[ID].end(); ++it )   {
    faceSize         += it->getFaceRect().size();
    facePosition     += it->getFaceRect().tl();
    leftEyePosition  += it->getLeftEye();
    rightEyePosition += it->getRightEye();
    yaw              += it->getHeadYaw();
    pitch            += it->getHeadPitch();
    std::vector<float> emotionPredictions = it->getEmotions();
    neutral          += emotionPredictions[0];
    happy            += emotionPredictions[1];
    surprise         += emotionPredictions[2];
    anger            += emotionPredictions[3];
    disgusted        += emotionPredictions[4];
    fear             += emotionPredictions[5];
    sadness          += emotionPredictions[6];
    mood             += it->getMood();
//    cv::Point eg = it->getEyeGaze();
//    eg.x = MAX(0,MIN(eg.x,960));
//    eg.y = MAX(0,MIN(eg.y,640));
////    eg.x = eg.x - 1136/2;
//    eg.y = eg.y - 640/2;
//    eyeGaze          += eg;
  }
  
  int sz             = personHistory[ID].size();
  face.x             = facePosition.x / sz;
  face.y             = facePosition.y / sz;
  face.width         = faceSize.width / sz;
  face.height        = faceSize.height / sz;
  leftEyePosition.x  /= sz;
  leftEyePosition.y  /= sz;
  rightEyePosition.x /= sz;
  rightEyePosition.y /= sz;
  yaw                /= sz;
  pitch              /= sz;
  neutral            /= sz;
  happy              /= sz;
  surprise           /= sz;
  anger              /= sz;
  disgusted          /= sz;
  fear               /= sz;
  sadness            /= sz;
  mood               /= sz;
  eyeGaze.x          /= sz;
  eyeGaze.y          /= sz;
  
  if ( face.area() <= 0) return;
  
  // Draw face detection
  cv::Rect biggerFace( face.x - ( face.width * 0.1f ), face.y - ( face.width * 0.1f ),
                      face.width + ( face.width * 0.2f ), face.height + ( face.width * 0.2f ) );
  cv::Rect  halfFace   = cv::Rect( face.x + ( face.width / 2 ), face.y + ( face.height / 2 ), face.width / 2, face.height / 2 );
  
  // Draw eyes
  cv::circle( frame, rightEyePosition, 3, KCOLOR_GREEN_1 );
  cv::circle( frame, leftEyePosition,  3, KCOLOR_GREEN_1 );
  
  // Draw Stats panel
  cv::Point stats_pos = cv::Point( biggerFace.x + ( biggerFace.width / 1.5 ), biggerFace.y + ( biggerFace.height / 1.5) );
  overlayPoint( stats_pos, _statsBkgView );
  
  drawCircle( biggerFace,
             _circleView,
             cv::Rect(stats_pos.x, stats_pos.y,_statsBkgView.frame.size.width,_statsBkgView.frame.size.height), KCOLOR_BLUE_3);
  
  
  // Draw emotions
  int barHeight = 11;
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_NEUTRAL,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_NEUTRAL + cv::Point( 50.0f * neutral, barHeight ),
          _neutralView,
          KCOLOR_GRAY_1);
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_HAPPY,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_HAPPY + cv::Point( 50.0f * happy, barHeight ),
          _happyView,
          KCOLOR_GREEN_2);
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_SURPRISE,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_SURPRISE + cv::Point( 50.0f * surprise, barHeight ),
          _surpriseView,
          KCOLOR_BLUE_2);
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_ANGER,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_ANGER + cv::Point( 50.0f * anger, barHeight ),
          _angerView,
          KCOLOR_RED_1);
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_DISGUSTED,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_DISGUSTED + cv::Point( 50.0f * disgusted, barHeight ),
          _disgustedView,
          KCOLOR_YELLOW_1);
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_FEAR,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_FEAR + cv::Point( 50.0f * fear, barHeight ),
          _fearView,
          KCOLOR_BROWN_1);
  drawBar(stats_pos + KPOINT_OFFSET_EMOTION_BAR_SADNESS,
          stats_pos + KPOINT_OFFSET_EMOTION_BAR_SADNESS + cv::Point( 50.0f * sadness, barHeight ),
          _sadnessView,
          KCOLOR_PURPLE_1);
  
  // Draw head gaze
  float yawValue   = ( yaw + 1.0f ) / 2.0f;
  float pitchValue = ( pitch + 1.0f ) / 2.0f;
  drawLine(cv::Point( halfFace.x, halfFace.y ),
           cv::Point( face.x + yawValue * face.width, face.y + pitchValue * face.height ),
           _headPose,
           KCOLOR_WHITE_1);
  
//  // Draw eye gaze
//  drawEyeGaze(eyeGaze, gazeView);
}


#pragma mark - Getters/Setters

- (void)setPerson:(Person *)p {
  _person = p;
}

- (Person *)getPerson {
  return _person;
}

- (void)releasePerson {
  delete _person;
}

- (void)dealloc {
  delete _person;
}

@end
