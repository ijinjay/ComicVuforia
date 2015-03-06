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

#import <QuartzCore/QuartzCore.h>
#import "ViewController.h"

@interface ImageTargetsViewController ()
@property (strong, nonatomic) UIButton *returnButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *voiceButton;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *expressionButton;

@end

@implementation ImageTargetsViewController


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
    // Create the EAGLView
    eaglView = [[ImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = eaglView;
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    // initialize the AR session
    [vapp initAR: (QCAR::GL_20) ARViewBoundsSize:viewFrame.size orientation:UIInterfaceOrientationPortrait];
}

- (void)addButtons {
    // add control button
    _returnButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 100, 30)];
    _switchButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 130, 100, 30)];
    _voiceButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 230, 100, 30)];
    _snapButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 330, 100, 30)];
    _expressionButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 430, 100, 30)];
    
    [_returnButton setTitle:@"返回" forState:UIControlStateNormal];
    [_switchButton setTitle:@"切换相机" forState:UIControlStateNormal];
    [_voiceButton setTitle:@"语音交互" forState:UIControlStateNormal];
    [_snapButton setTitle:@"拍照" forState:UIControlStateNormal];
    [_expressionButton setTitle:@"表情识别" forState:UIControlStateNormal];
    
    // set backgroundcolor
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:[user objectForKey:@"backgroundcolor"]];
    NSInteger colorIndex = [user integerForKey:@"colorIndex"];
    if ([user objectForKey:@"colorcount"] != nil) {
        colorIndex = (colorIndex + 1)%([user integerForKey:@"colorcount"]);
        [user setInteger:colorIndex forKey:@"colorIndex"];
    }
    
    [_returnButton setTitleColor:color forState:UIControlStateNormal];
    [_switchButton setTitleColor:color forState:UIControlStateNormal];
    [_voiceButton setTitleColor:color forState:UIControlStateNormal];
    [_snapButton setTitleColor:color forState:UIControlStateNormal];
    [_expressionButton setTitleColor:color forState:UIControlStateNormal];
    
    [_returnButton addTarget:self action:@selector(returnFunc:) forControlEvents:UIControlEventTouchDown];
    [_switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchDown];
    [_voiceButton addTarget:self action:@selector(voiceHandle:) forControlEvents:UIControlEventTouchDown];
    [_snapButton addTarget:self action:@selector(snapImage:) forControlEvents:UIControlEventTouchDown];
    [_expressionButton addTarget:self action:@selector(expressionRecognize:) forControlEvents:UIControlEventTouchDown];
    
    [eaglView addSubview:_returnButton];
    [eaglView addSubview:_switchButton];
    [eaglView addSubview:_voiceButton];
    [eaglView addSubview:_snapButton];
    [eaglView addSubview:_expressionButton];
}

- (void)returnFunc:(id)sender {
    UIStoryboard * st =  [UIStoryboard storyboardWithName:@"storyboardWithViewControllerName" bundle:nil];
    ViewController * vc =   [st instantiateViewControllerWithIdentifier:@"ViewControllerId"];
}
- (void)switchCamera:(id)sender {
    
}
- (void)voiceHandle:(id)sender {
    
}
- (void)setButtonHidden:(BOOL)hidden {
    _returnButton.hidden = hidden;
    _switchButton.hidden = hidden;
    _snapButton.hidden = hidden;
    _voiceButton.hidden = hidden;
    _expressionButton.hidden = hidden;
}
- (void)snapImage:(id)sender {
    [self setButtonHidden:YES];
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageWriteToSavedPhotosAlbum(viewImage, nil, nil, nil);
    
    [self setButtonHidden:NO];
}
- (void)expressionRecognize:(id)sender {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addGestureRecognizer:tapGestureRecognizer];
    [self prefersStatusBarHidden];
    
    [self addButtons];
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

- (void)finishOpenGLESCommands {
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}


- (void)freeOpenGLESResources {
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if ((dataSetStonesAndChips == NULL) || (dataSetTarmac == NULL)) {
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
        bool isContinuousAutofocus = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
//        SampleAppMenu * menu = [SampleAppMenu instance];
//        [menu setSelectionValueForCommand:C_AUTOFOCUS value:isContinuousAutofocus];
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


#pragma mark - left menu

typedef enum {
    C_EXTENDED_TRACKING,
    C_AUTOFOCUS,
    C_FLASH,
    C_CAMERA_FRONT,
    C_CAMERA_REAR,
    SWITCH_TO_TARMAC,
    SWITCH_TO_STONES_AND_CHIPS,
} MENU_COMMAND;

//- (void) prepareMenu {
//    
//    SampleAppMenu * menu = [SampleAppMenu prepareWithCommandProtocol:self title:@"Image Targets"];
//    SampleAppMenuGroup * group;
//    
//    group = [menu addGroup:@""];
//    [group addTextItem:@"Vuforia Samples" command:-1];
//
//    group = [menu addGroup:@""];
//    [group addSelectionItem:@"Extended Tracking" command:C_EXTENDED_TRACKING isSelected:NO];
//    [group addSelectionItem:@"Autofocus" command:C_AUTOFOCUS isSelected:NO];
//    [group addSelectionItem:@"Flash" command:C_FLASH isSelected:NO];
//
//    group = [menu addSelectionGroup:@"CAMERA"];
//    [group addSelectionItem:@"Front" command:C_CAMERA_FRONT isSelected:NO];
//    [group addSelectionItem:@"Rear" command:C_CAMERA_REAR isSelected:YES];
//
//    group = [menu addSelectionGroup:@"DATABASE"];
//    [group addSelectionItem:@"Stones & Chips" command:SWITCH_TO_STONES_AND_CHIPS isSelected:YES];
//    [group addSelectionItem:@"Tarmac" command:SWITCH_TO_TARMAC isSelected:NO];
//}
//
//- (bool) menuProcess:(SampleAppMenu *) menu command:(int) command value:(bool) value{
//    bool result = true;
//    NSError * error = nil;
//    
//    switch(command) {
//        case C_FLASH:
//            if (!QCAR::CameraDevice::getInstance().setFlashTorchMode(value)) {
//                result = false;
//            }
//            break;
//            
//        case C_EXTENDED_TRACKING:
//            result = [self setExtendedTrackingForDataSet:dataSetCurrent start:value];
//            if (result) {
//                [eaglView setOffTargetTrackingMode:value];
//                extendedTrackingIsOn = value;
//            }
//            break;
//            
//        case C_CAMERA_FRONT:
//        case C_CAMERA_REAR: {
//            if ([vapp stopCamera:&error]) {
//                result = [vapp startAR:(command == C_CAMERA_FRONT) ? QCAR::CameraDevice::CAMERA_FRONT:QCAR::CameraDevice::CAMERA_BACK error:&error];
//            } else {
//                result = false;
//            }
//
//        }
//            break;
//            
//        case C_AUTOFOCUS: {
//            int focusMode = value ? QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO : QCAR::CameraDevice::FOCUS_MODE_NORMAL;
//            result = QCAR::CameraDevice::getInstance().setFocusMode(focusMode);
//        }
//            break;
//            
//        case SWITCH_TO_TARMAC:
//            [self setExtendedTrackingForDataSet:dataSetCurrent start:NO];
//            switchToTarmac = YES;
//            switchToStonesAndChips = NO;
//            break;
//            
//        case SWITCH_TO_STONES_AND_CHIPS:
//            [self setExtendedTrackingForDataSet:dataSetCurrent start:NO];
//            switchToStonesAndChips = YES;
//            switchToTarmac = NO;
//            break;
//            
//        default:
//            result = false;
//            break;
//    }
//    return result;
//}

@end
