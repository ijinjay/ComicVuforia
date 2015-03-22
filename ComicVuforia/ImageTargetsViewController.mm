/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/
#import "AppDelegate.h"
#import "ImageTargetsViewController.h"
#import <QCAR/QCAR.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/ObjectTracker.h>
#import <QCAR/Trackable.h>
#import <QCAR/DataSet.h>
#import <QCAR/CameraDevice.h>
#import <QCAR/Image.h>

#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"
#import <GLKit/GLKit.h>

// Speech Recognize
#import <iflyMSC/IFlyRecognizerViewDelegate.h>
#import <iflyMSC/IFlyRecognizerView.h>
#import <iflyMSC/IFlySpeechUtility.h>
#import <iflyMSC/IFlySpeechError.h>

#import <AVFoundation/AVFoundation.h>
#import "CustomButton.h"
#import "MBProgressHUD.h"

// facial recognise
#import "Reachability.h"

@interface ImageTargetsViewController () <IFlyRecognizerViewDelegate>
@property (strong, nonatomic) CustomButton *returnButton;
@property (strong, nonatomic) CustomButton *switchButton;
@property (strong, nonatomic) CustomButton *speechButton;
@property (strong, nonatomic) CustomButton *snapButton;
@property (strong, nonatomic) CustomButton *expressionButton;

@property (nonatomic) BOOL isBackCamera;

@property (nonatomic, strong) IFlyRecognizerView *speechView;
@property (nonatomic, strong) NSString *speechResult; // speech recognize result
@property (nonatomic, strong) NSString *endStr;       // speech recognize end punctuation

@property (nonatomic) BOOL analyzeExpression;

// facial recognize
@property (nonatomic) Reachability *internetReachability;

@end

@implementation ImageTargetsViewController

NSString *fpp_api_key = @"ead94b65b97e8f4be31f795fbda17b92";
NSString *fpp_secret_key = @"ZSUHkT83T3O-ZEn55x56Yynop3aZpKA1";

- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}
- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    // on resume, we reset the flash and the associated menu item
    QCAR::CameraDevice::getInstance().setFlashTorchMode(false);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)loadView {
    // initilize variables
    if (self) {
        vapp = [[QCARSession alloc] initWithDelegate:self];
        
        // Custom initialization
        self.title = @"Comic Vuforia";
        // Create the EAGLView with the screen dimensions
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        viewFrame = screenBounds;
        
        // If this device has a retina display, scale the view bounds that will
        // be passed to QCAR; this allows it to calculate the size and position of
        // the viewport correctly when rendering the video background
        if (YES == vapp.isRetinaDisplay) {
            viewFrame.size.width *= 2.0;
            viewFrame.size.height *= 2.0;
        }
        
        dataSetCurrent = nil;
        extendedTrackingIsOn = NO;
        
        // a single tap will trigger a single autofocus operation
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
        
        // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(pauseAR)
         name:UIApplicationWillResignActiveNotification
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(resumeAR)
         name:UIApplicationDidBecomeActiveNotification
         object:nil];
        
    }
    _isBackCamera = YES;
    _analyzeExpression = NO;
    // Create the EAGLView
    eaglView = [[ImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = eaglView;
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    // facial recognize initial
    // Check for internet connection
    self.internetReachability = [Reachability reachabilityForInternetConnection];
	[self.internetReachability startNotifier];
    
    // initialize the AR session
    [vapp initAR: (QCAR::GL_20) ARViewBoundsSize:viewFrame.size orientation:UIInterfaceOrientationPortrait];
}
- (void)addButtons {
    // add control button
    CGFloat fontSize = 20.0;
    NSInteger scale = 1;
    // 更新iPad的界面
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        scale = 2;
    }
    
    CGFloat deviceWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat deviceHeight= [[UIScreen mainScreen] bounds].size.height;
    // set backgroundcolor
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:[user objectForKey:@"backgroundcolor"]];
    NSInteger colorIndex = [user integerForKey:@"colorIndex"];
    if ([user objectForKey:@"colorcount"] != nil) {
        colorIndex = (colorIndex + 1)%([user integerForKey:@"colorcount"]);
        [user setInteger:colorIndex forKey:@"colorIndex"];
    }
    
    UIFont *buttonFont = [UIFont systemFontOfSize:fontSize * scale];
    _returnButton = [[CustomButton alloc] initWithFrame:CGRectMake(0, 0, deviceWidth/3.0, 40*scale) andTitle:@"返回" andBackgroundColor:color andFont:buttonFont];
    _switchButton = [[CustomButton alloc] initWithFrame:CGRectMake(deviceWidth/3.0*2, 0, deviceWidth/3.0, 40*scale) andTitle:@"切换相机" andBackgroundColor:color andFont:buttonFont];
    _speechButton = [[CustomButton alloc] initWithFrame:CGRectMake(0, deviceHeight-40*scale, deviceWidth/3.0, 40*scale) andTitle:@"语音交互" andBackgroundColor:color andFont:buttonFont];
    _snapButton   = [[CustomButton alloc] initWithFrame:CGRectMake(deviceWidth/3.0, deviceHeight-40*scale*1.5, deviceWidth/3.0, 40*scale*1.5) andTitle:@"拍照" andBackgroundColor:color andFont:buttonFont];
    _expressionButton = [[CustomButton alloc] initWithFrame:CGRectMake(deviceWidth/3.0*2, deviceHeight-40*scale, deviceWidth/3.0, 40*scale) andTitle:@"表情识别" andBackgroundColor:color andFont:buttonFont];
    
    [_returnButton addTarget:self action:@selector(returnFunc:) forControlEvents:UIControlEventTouchDown];
    [_switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchDown];
    [_speechButton addTarget:self action:@selector(speechHandle:) forControlEvents:UIControlEventTouchDown];
    [_snapButton addTarget:self action:@selector(snapImage:) forControlEvents:UIControlEventTouchDown];
    [_expressionButton addTarget:self action:@selector(expressionRecognize:) forControlEvents:UIControlEventTouchDown];
    
    [eaglView addSubview:_returnButton];
    [eaglView addSubview:_switchButton];
    [eaglView addSubview:_speechButton];
    [eaglView addSubview:_snapButton];
    [eaglView addSubview:_expressionButton];
}

// button callback
- (void)returnFunc:(id)sender {
    UIStoryboard * st =  [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController * vc =   [st instantiateViewControllerWithIdentifier:@"home"];
    [self presentViewController:vc animated:YES completion:nil];
}
- (void)switchCamera:(id)sender {
    NSError * error = nil;
    if ([vapp stopCamera:&error]) {
        [vapp startAR:(_isBackCamera ? QCAR::CameraDevice::CAMERA_FRONT : QCAR::CameraDevice::CAMERA_BACK) error:&error];
        _isBackCamera = !_isBackCamera;
    }
}
- (void)speechHandle:(id)sender {
    
    [eaglView addSubview:_speechView];
    
    [_speechView start];
}
- (void)setButtonHidden:(BOOL)hidden {
    _returnButton.hidden = hidden;
    _switchButton.hidden = hidden;
    _snapButton.hidden = hidden;
    _speechButton.hidden = hidden;
    _expressionButton.hidden = hidden;
}

- (void)snapImage:(id)sender {
    [self setButtonHidden:YES];

    [eaglView savePhoto];
    
    [self setButtonHidden:NO];
    
    // add a fulfillment tip
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"拍照成功";
    [hud hide:YES afterDelay:0.5];
}
- (void)expressionRecognize:(id)sender {
    // Check if internet connection is available
    NetworkStatus netStatus = [self.internetReachability currentReachabilityStatus];
    
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:@"未能连接到互联网"
                               message:@"面部表情识别需要使用互联网!"
                              delegate:nil
                     cancelButtonTitle:@"确认"
                     otherButtonTitles:nil];
    
    // Continue if redistribution is already activated or can be activated now
    if (netStatus == NotReachable) {
        [alert show];
        _analyzeExpression = NO;
    } else {
        _analyzeExpression = YES;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addGestureRecognizer:tapGestureRecognizer];
    [self prefersStatusBarHidden];

    [self addButtons];
    
    // add iflyspeechrecognize view
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"54faa960"];
    [IFlySpeechUtility createUtility:initString];
    _speechView = [[IFlyRecognizerView alloc] initWithCenter:CGPointMake([[UIScreen mainScreen] bounds].size.width / 2.0, [[UIScreen mainScreen] bounds].size.height / 2.0)];
    [_speechView setParameter:@"iat" forKey:@"domain"];
    [_speechView setParameter:@"500" forKey:@"vad_eos"];
    _speechView.delegate = self;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [vapp stopAR:nil];
    // Be a good OpenGL ES citizen: now that QCAR is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [eaglView finishOpenGLESCommands];
    [eaglView freeOpenGLESResources];
	
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = nil;

    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)finishOpenGLESCommands {
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}
- (void)freeOpenGLESResources {
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}


#pragma mark - loading animation

- (void) showLoadingAnimation {
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    CGRect indicatorBounds = CGRectMake(mainBounds.size.width / 2 - 12,
                                        mainBounds.size.height / 2 - 12, 24, 24);
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
                                                  initWithFrame:indicatorBounds];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}
- (void) hideLoadingAnimation {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}

#pragma mark - ApplicationControl

- (bool) doInitTrackers {
    // Initialize the image or marker tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    
    // Image Tracker...
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::ObjectTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    NSLog(@"Successfully initialized ObjectTracker.");
    return true;
}
- (bool) doLoadTrackersData {
    dataSetStonesAndChips = [self loadObjectTrackerDataSet:@"StonesAndChips.xml"];
    dataSetTarmac = [self loadObjectTrackerDataSet:@"Tarmac.xml"];
    dataLF = [self loadObjectTrackerDataSet:@"lf.xml"];
    
    if ((dataSetStonesAndChips == NULL) || (dataSetTarmac == NULL) || (dataLF == NULL)) {
        NSLog(@"Failed to load datasets");
        return NO;
    }
    if (! [self activateDataSet:dataSetStonesAndChips]) {
        NSLog(@"Failed to activate dataset");
        return NO;
    }
    
    return YES;
}
- (bool) doStartTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ObjectTracker::getClassType());
    if(tracker == 0) {
        return NO;
    }

    tracker->start();
    return YES;
}
// callback: the AR initialization is done
- (void) onInitARDone:(NSError *)initError {
    [self hideLoadingAnimation];
    
    if (initError == nil) {
        // If you want multiple targets being detected at once,
        // you can comment out this line
        // QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 2);
        
        NSError * error = nil;
        [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        
        // by default, we try to set the continuous auto focus mode
        // and we update menu to reflect the state of continuous auto-focus
        QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
        dispatch_async( dispatch_get_main_queue(), ^{

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[initError localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kMenuDismissViewController" object:nil];
}

- (void) onQCARUpdate: (QCAR::State *) state {
    if (switchToTarmac) {
        [self activateDataSet:dataSetTarmac];
        switchToTarmac = NO;
    }
    if (switchToStonesAndChips) {
        [self activateDataSet:dataSetStonesAndChips];
        switchToStonesAndChips = NO;
    }
    if (switchToLF) {
        [self activateDataSet:dataLF];
        switchToLF = NO;
    }
    
    // analyze facial expressionz
    QCAR::setFrameFormat(QCAR::RGB888, YES);
    if (_analyzeExpression) {
        QCAR::Frame frame = state->getFrame();
        NSLog(@"-------");
        for (int i = 0; i < frame.getNumImages(); i++) {
            const QCAR::Image *qcarImage = frame.getImage(i);
            if (qcarImage->getFormat() == QCAR::RGB888) {
                NSData * imageData = [NSData dataWithBytes:qcarImage->getPixels()
                                                    length:(QCAR::getBufferSize(qcarImage->getWidth(), qcarImage->getHeight(), QCAR::RGB888))];
                
                NSLog(@"is address equal? %d", (void *)imageData.bytes == (void *)qcarImage->getPixels());
                
                if (imageData != nil) {
                    NSLog(@"success get image data");
                    // compress the image data
                    CGColorSpace *colorSpace = CGColorSpaceCreateDeviceRGB();
                    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
                    CGImage *imageRef = CGImageCreate(qcarImage->getWidth(), qcarImage->getHeight(), 8, 8*3, qcarImage->getStride(), colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, nil, false, kCGRenderingIntentDefault);
                    
                    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:UIImageOrientationRightMirrored];
                    
                    CGImageRelease(imageRef);
                    CGDataProviderRelease(provider);
                    CGColorSpaceRelease(colorSpace);
                    
                    NSData *imgData = UIImageJPEGRepresentation(finalImage, 0);
                    
                    // post the imgdata
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                        UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil);
                        NSData *result = [self uploadData:imgData];
                        NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:nil];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // 更新界面
                            NSString *dict = [jsonResult objectForKey:@"face"];
                        
                        });
                    });
                }

            }
        }
        _analyzeExpression = NO;
    }
}

// Load the image tracker data set
- (QCAR::DataSet *)loadObjectTrackerDataSet:(NSString*)dataFile {
    NSLog(@"loadObjectTrackerDataSet (%@)", dataFile);
    QCAR::DataSet * dataSet = NULL;
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::STORAGE_APPRESOURCE)) {
                NSLog(@"ERROR: failed to load data set");
                objectTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}
- (bool) doStopTrackers {
    // Stop the tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ObjectTracker::getClassType());
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}
- (bool) doUnloadTrackersData {
    [self deactivateDataSet: dataSetCurrent];
    dataSetCurrent = nil;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    // Destroy the data sets:
    if (!objectTracker->destroyDataSet(dataSetTarmac)) {
        NSLog(@"Failed to destroy data set Tarmac.");
    }
    if (!objectTracker->destroyDataSet(dataSetStonesAndChips)) {
        NSLog(@"Failed to destroy data set Stones and Chips.");
    }
    if (!objectTracker->destroyDataSet(dataLF)) {
        NSLog(@"Failed to destroy data set LF");
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}
- (BOOL)activateDataSet:(QCAR::DataSet *)theDataSet {
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil) {
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    }
    else {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet)) {
            NSLog(@"Failed to activate data set.");
        }
        else {
            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        [self setExtendedTrackingForDataSet:dataSetCurrent start:extendedTrackingIsOn];
    }
    
    return success;
}
- (BOOL)deactivateDataSet:(QCAR::DataSet *)theDataSet {
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent)) {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ObjectTracker* objectTracker = static_cast<QCAR::ObjectTracker*>(trackerManager.getTracker(QCAR::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.");
    }
    else {
        // Activate the data set:
        if (!objectTracker->deactivateDataSet(theDataSet)) {
            NSLog(@"Failed to deactivate data set.");
        }
        else {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}
- (BOOL) setExtendedTrackingForDataSet:(QCAR::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        QCAR::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking()) {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            if (!trackable->stopExtendedTracking()) {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}
- (bool) doDeinitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::ObjectTracker::getClassType());
    return YES;
}
- (void)autofocus:(UITapGestureRecognizer *)sender {
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}
- (void)cameraPerformAutoFocus {
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

#pragma mark - IFlyRecognization
/** 回调返回识别结果
 
 @param resultArray 识别结果，NSArray的第一个元素为NSDictionary，NSDictionary的key为识别结果，value为置信度
 @param isLast      -[out] 是否最后一个结果
 */
- (void)onResult:(NSArray *)resultArray isLast:(BOOL) isLast {
    NSArray * temp = [[NSArray alloc]init];
    NSString * str = [[NSString alloc]init];
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = resultArray[0];
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    
    NSLog(@"听写结果：%@",result);
    //---------讯飞语音识别JSON数据解析---------//
    NSError * error;
    NSData * data = [result dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"data: %@",data);
    NSDictionary * dic_result =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSArray * array_ws = [dic_result objectForKey:@"ws"];
    //遍历识别结果的每一个单词
    for (int i=0; i<array_ws.count; i++) {
        temp = [[array_ws objectAtIndex:i] objectForKey:@"cw"];
        NSDictionary * dic_cw = [temp objectAtIndex:0];
        str = [str  stringByAppendingString:[dic_cw objectForKey:@"w"]];
        NSLog(@"识别结果:%@",[dic_cw objectForKey:@"w"]);
    }
    NSLog(@"最终的识别结果:%@",str);
    //去掉识别结果最后的标点符号
    if ([str isEqualToString:@"。"] || [str isEqualToString:@"？"] || [str isEqualToString:@"！"]) {
        NSLog(@"末尾标点符号：%@",str);
        _endStr = str;
    } else {
        _speechResult = str;
    }
    if (isLast) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = _speechResult;
        if (_speechResult != nil) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self parseText:_speechResult];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 更新界面
                });
            });
        }
        [hud hide:YES afterDelay:1.0];
    }
}
/** 识别结束回调
 
 @param error 识别结束错误码
 */
- (void)onError: (IFlySpeechError *) error {
    NSLog(@"%@", [error errorDesc]);
}

- (void)saySomething:(NSString *)str{
    AVSpeechSynthesizer *avSpeech = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:str];
    utterance.rate = AVSpeechUtteranceMaximumSpeechRate / 4.0f;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-guoyu"]; // defaults to your system language
    [avSpeech speakUtterance:utterance];
}
- (void)parseText:(NSString *)str {
    
    if (str == nil) {
        NSLog(@"空字符串");
        [self saySomething:@"抱歉，您说的是什么？"];
    } else if ([str compare:@"你是谁"] == NSOrderedSame || [str compare:@"你是谁？"] == NSOrderedSame){
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        NSString *name = [user objectForKey:@"modelName"];
        [self saySomething:[@"我是" stringByAppendingString:name]];
    }
    else if ([str compare:@"你好"] == NSOrderedSame || [str compare:@"你好。"] == NSOrderedSame) {
        [self saySomething:@"你好"];
        [eaglView sayHello];
    }
    else if ([str rangeOfString:@"舞"].location != NSNotFound){
        [eaglView dance];
    }
    else if (([str rangeOfString:@"萌"].location != NSNotFound) || ([str rangeOfString:@"跳"].location != NSNotFound)) {
        NSLog(@"萌一个");
        [self saySomething:@"好的"];
    } else if ([str rangeOfString:@"转体"].location != NSNotFound){
        [self saySomething:@"好的"];
        NSString *newString = [[str componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                               componentsJoinedByString:@""];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *myNumber = [f numberFromString:newString];
        NSLog(@"-----%@", myNumber);
        [eaglView rotateModel:(myNumber.intValue)*M_PI/180.0];
    }
    else {
        NSLog(@"未能识别出的语义");
        [self saySomething:@"真抱歉，不能识别您的语义。"];
    }
}

#pragma mark - Faceplusplus

-(NSData *)uploadData:(NSData*)imgData{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://apicn.faceplusplus.com/v2/detection/detect?api_key=ead94b65b97e8f4be31f795fbda17b92&api_secret=ZSUHkT83T3O-ZEn55x56Yynop3aZpKA1&attribute=gender,age,smiling"]]; //创建请求对象并设置请求路径
    // Init the URLRequest
    [request setHTTPMethod:@"POST"];
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    // add image data
    if (imgData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"img\"; filename=\"image.jpeg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imgData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];
    
    //上传文件开始
    NSURLResponse *response;
    NSError *error;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (returnData == nil) {
        NSLog(@"get nothing- -");
        NSLog(@"response: %@", response);
        NSLog(@"error: %@", error);
    }
    //返回获得返回值
    return returnData;
}

@end
