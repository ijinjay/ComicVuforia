/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/Image.h>

#import "ImageTargetsEAGLView.h"
#import "SampleApplicationUtils.h"
#import "SampleMath.h"
#import <GLKit/GLKit.h>

NSDictionary *readPlist(NSString *keyWord) {
    NSDictionary *result;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"model.plist"]];
    result = [plistDict objectForKey:keyWord];
    
    return result;
}

@interface ImageTargetsEAGLView (PrivateMethods)

- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;
- (void)savePhoto;
@end


@implementation ImageTargetsEAGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(QCARSession *) app {
    self = [super initWithFrame:frame];
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:2.0f];
        }
        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        // init Scenekit
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        if ([user objectForKey:@"modelName"] == nil) {
            [user setObject:@"Histoire" forKey:@"modelName"];
        }
        NSString *modelName = [user objectForKey:@"modelName"];
        NSDictionary *dict = readPlist(modelName);
        assert(dict != nil);
        _scene = [SCNScene sceneNamed:[dict objectForKey:@"filePath"]];
        NSLog(@"%@", [dict objectForKey:@"filePath"]);
        
        if (_scene == nil) {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            _scene = [SCNScene sceneWithURL:[documentsDirectoryURL URLByAppendingPathComponent:((NSString *)[dict objectForKey:@"filePath"])] options:nil error:nil];
            NSLog(@"scene is not nil, %@", _scene);
        }
        
        _scnRender = [SCNRenderer rendererWithContext:(void *)context options:nil];
        // create and add a camera to the scene
        _cameraNode = [SCNNode node];
        _cameraNode.camera = [SCNCamera camera];
        [_scene.rootNode addChildNode:_cameraNode];
        _cameraNode.camera.zNear = 2.0f;
        _cameraNode.camera.zFar = 2000.0f;
        // place the camera
        // create and add an ambient light to the scene
        SCNNode *ambientLightNode = [SCNNode node];
        ambientLightNode.light = [SCNLight light];
        ambientLightNode.light.type = SCNLightTypeAmbient;
        ambientLightNode.light.color = [UIColor darkGrayColor];
        [self.scene.rootNode addChildNode:ambientLightNode];
        
//        // create and add a particalSystem node to the scene
//        SCNNode *pNode = [SCNNode node];
//        [self.scene.rootNode addChildNode:pNode];
//        pNode.hidden = NO;
        
        _fixAngleX = [[dict objectForKey:@"angleX"] intValue];
        _fixAngleY = [[dict objectForKey:@"angleY"] intValue];
        _angleX = _fixAngleX;
        _angleY = _fixAngleY;
        
        NSDictionary *fixedPosition = [dict objectForKey:@"fixedPosition"];
        _fixedPostionMatrix = SCNMatrix4MakeTranslation([[fixedPosition objectForKey:@"x"] intValue], [[fixedPosition objectForKey:@"y"] intValue],[[fixedPosition objectForKey:@"z"] intValue]);
        
        float scale = [[dict objectForKey:@"scale"] intValue];
        _scaleMatrix = SCNMatrix4MakeScale(scale, scale, scale);
        _rootNode = [_scene.rootNode childNodeWithName:[dict objectForKey:@"rootNode"] recursively:YES];
        
        // fixed the oringinal pos
        SCNMatrix4 rotMatrix = SCNMatrix4Mult(SCNMatrix4MakeRotation(_angleX, 0, 1, 0), SCNMatrix4MakeRotation(_angleY, 1, 0, 0));
        rotMatrix = SCNMatrix4Mult(rotMatrix, _fixedPostionMatrix);
        _rootNode.transform = SCNMatrix4Mult(rotMatrix, _scaleMatrix);
        
        [_scnRender setScene:_scene];
    }
    
    return self;
}

- (void)dealloc {
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
}
- (void)finishOpenGLESCommands {
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}
- (void)freeOpenGLESResources {
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR {
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // draw videobackground
    // Render video background and retrieve tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    QCAR::Renderer::getInstance().end();
    
    // show the model
    static int numDidnotFoundTrack = 0;
    numDidnotFoundTrack ++;
    
    // we've detected an image
    if (state.getNumTrackableResults() != 0 ) {
        // if long time no track, we should reinitial _angleY and _angleZ
        if (numDidnotFoundTrack > 60) {
            _angleY = _fixAngleY;
            _angleX = _fixAngleX;
        }
        for (int i = 0; (i < state.getNumTrackableResults()); ++i) {
            
            // Get the trackable
            const QCAR::TrackableResult* result = state.getTrackableResult(i);
            // const QCAR::Trackable& trackable = result->getTrackable();
            QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
            QCAR::Matrix44F modelViewProjection;
            SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
//            SampleApplicationUtils::multiplyMatrix(&modelViewMatrix.data[0], &vapp.projectionMatrix.data[0], &modelViewProjection.data[0]);
            
            // extract the camera position
//            QCAR::Matrix44F inverseMV = SampleMath::Matrix44FInverse(modelViewMatrix);
//            QCAR::Matrix44F invTranspMV = SampleMath::Matrix44FTranspose(inverseMV);
//            float cam_x = invTranspMV.data[12];
//            float cam_y = invTranspMV.data[13];
//            float cam_z = invTranspMV.data[14];
//            float cam_right_x = invTranspMV.data[0];
//            float cam_right_y = invTranspMV.data[1];
//            float cam_right_z = invTranspMV.data[2];
//            float cam_up_x = -invTranspMV.data[4];
//            float cam_up_y = -invTranspMV.data[5];
//            float cam_up_z = -invTranspMV.data[6];
//            float cam_dir_x = invTranspMV.data[8];
//            float cam_dir_y = invTranspMV.data[9];
//            float cam_dir_z = invTranspMV.data[10];
//            
//            float w = sqrt(cam_right_x*cam_right_x + cam_up_y*cam_up_y + cam_dir_z*cam_dir_z + 1*1) / 2.0;
//            float x = (cam_dir_y - cam_up_z) / (4 * w);
//            float y = (cam_right_z - cam_dir_x) / (4 * w);
//            float z = (cam_up_x - cam_right_y) / (4 * w);
            
//            _cameraNode.position = SCNVector3Make(cam_x, cam_y, cam_z);
//            _cameraNode.rotation = SCNVector4Make(x, y, z, w);
//            _cameraNode.orientation = SCNVector4Make(x, y, z, w);
//            [self printMat:&invTranspMV];
//            _cameraNode.
//            _cameraNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4MakeWithArray(invTranspMV.data));
            
            // set the camera position
            GLKMatrix4 mvp = GLKMatrix4MakeWithArray(modelViewProjection.data);
            _cameraNode.camera.projectionTransform = SCNMatrix4FromGLKMatrix4(mvp);
            
            [_scnRender render];
        }
        numDidnotFoundTrack = 0;
    }
    
    [self presentFramebuffer];
}

- (void)printMat:(QCAR::Matrix44F *)mp{
    for (int i = 0; i < 4; i ++) {
        for (int j = 0; j < 4; j ++) {
            printf("%f, ", (*mp).data[4*i + j]);
        }
        printf("\n");
    }
}

- (void)printNode:(SCNNode *)node {
    printf("position:%lf, %lf, %lf\n", node.position.x, node.position.y, node.position.z);
    printf("rotation:%lf, %lf, %lf, %lf\n", node.rotation.x, node.rotation.y, node.rotation.z, node.rotation.w);
}
//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)createFramebuffer {
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}
- (void)deleteFramebuffer {
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}
- (void)setFramebuffer {
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}
- (BOOL)presentFramebuffer {
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark User Event Handle

- (void)savePhoto{
    UIGraphicsBeginImageContext(self.frame.size);
    [self drawViewHierarchyInRect:self.frame afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    
    CGPoint lastLoc = [touch previousLocationInView:self];
    CGPoint diff = CGPointMake(lastLoc.x - location.x, lastLoc.y - location.y);
    
    // Histoire is a special node who need spetical care.
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSString *modelName = [user objectForKey:@"modelName"];
    int symbol = -1;
    if ([modelName compare:@"Histoire"] == NSOrderedSame) {
        symbol = 1;
    }
    
    _angleY = _angleY - GLKMathDegreesToRadians(diff.y / 2.0);
    _angleX = _angleX + symbol * GLKMathDegreesToRadians(diff.x / 2.0);
    
    // set the transform of the model. tranform = rotMatrix * fixedPositionMatrix * scaleMatrix
    SCNMatrix4 rotMatrix = SCNMatrix4Mult(SCNMatrix4MakeRotation(_angleX, 0, 1, 0), SCNMatrix4MakeRotation(_angleY, 1, 0, 0));
    rotMatrix = SCNMatrix4Mult(rotMatrix, _fixedPostionMatrix);
    _rootNode.transform = SCNMatrix4Mult(rotMatrix, _scaleMatrix);
    
}
- (void)rotateModel:(float) angle{
    [_rootNode runAction:[SCNAction rotateByX:0 y:angle z:0  duration:1]];
}
- (SCNNode *)getNodebyName:(NSString *)name {
    SCNNode *node = [_rootNode childNodeWithName:name recursively:YES];
    return node;
}
- (void)dance {
    
    [SCNTransaction begin];
    _rootNode.position = SCNVector3Make(0, 50, 0);
    [self rotateModel:M_PI*6];
    [SCNTransaction setAnimationDuration:0.5];
    [SCNTransaction setCompletionBlock:^(){
        [SCNTransaction begin];
        _rootNode.position = SCNVector3Make(0, 0, 0);
        [SCNTransaction setAnimationDuration:0.5];
        [SCNTransaction setCompletionBlock:^(){
            [self sayHello];
            [self walk];
        }];
        [SCNTransaction commit];
    }];
    [SCNTransaction commit];
    
}
- (void)legMoveForward:(SCNNode *)up down:(SCNNode*)down skirt:(SCNNode *)skirt onCompltetion:(void (^)())block{
    if (skirt != nil) {
        [skirt runAction:[SCNAction rotateByX:M_PI/6 y:0 z:0 duration:0.4] completionHandler:^(){
            [skirt runAction:[SCNAction rotateByX:-M_PI/6 y:0 z:0 duration:0.4]];
        }];
    }
    [up runAction:[SCNAction rotateByX:M_PI/6 y:0 z:0 duration:0.4] completionHandler:^(){
        [up runAction:[SCNAction rotateByX:-M_PI/6 y:0 z:0 duration:0.4]];
    }];
    [down runAction:[SCNAction rotateByX:-M_PI/6 y:0 z:0 duration:0.4] completionHandler:^(){
        [down runAction:[SCNAction rotateByX:M_PI/6 y:0 z:0 duration:0.4] completionHandler:block];
    }];
}
- (void)walk{
    SCNNode *ll1 = [self getNodebyName:@"L_leg_01"];
    SCNNode *ll2 = [self getNodebyName:@"L_leg_02"];
    SCNNode *rl1 = [self getNodebyName:@"R_leg_01"];
    SCNNode *rl2 = [self getNodebyName:@"R_leg_02"];
    
    SCNNode *lskirt = [self getNodebyName:@"FL_skirt_02"];
    SCNNode *rskirt = [self getNodebyName:@"FR_skirt_02"];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSString *modelName = [user objectForKey:@"modelName"];
    if ([modelName compare:@"Histoire"] == NSOrderedSame) {
        [self legMoveForward:ll1 down:ll2 skirt:lskirt onCompltetion:^(){
            [self legMoveForward:rl1 down:rl2 skirt:rskirt onCompltetion:nil];
        }];
    } else {
        [ll1 runAction:[SCNAction rotateByX:0 y:-M_PI/6 z:0 duration:0.4] completionHandler:^(){
            [ll1 runAction:[SCNAction rotateByX:0 y:+M_PI/6 z:0 duration:0.4]];
        }];
        [ll2 runAction:[SCNAction rotateByX:0 y:+M_PI/6 z:0 duration:0.4] completionHandler:^(){
            [ll2 runAction:[SCNAction rotateByX:0 y:-M_PI/6 z:0 duration:0.4] completionHandler:^(){
                [rl1 runAction:[SCNAction rotateByX:0 y:-M_PI/6 z:0 duration:0.4] completionHandler:^(){
                    [rl1 runAction:[SCNAction rotateByX:0 y:+M_PI/6 z:0 duration:0.4]];
                }];
                [rl2 runAction:[SCNAction rotateByX:0 y:+M_PI/6 z:0 duration:0.4] completionHandler:^(){
                    [rl2 runAction:[SCNAction rotateByX:0 y:-M_PI/6 z:0 duration:0.4]];
                }];
            }];
        }];
    }
}
- (void)sayHello {
    SCNNode *R_arm = [self getNodebyName:@"R_arm"];
    SCNNode *R_elbow = [self getNodebyName:@"R_elbow"];
    SCNNode *R_hand = [self getNodebyName:@"R_hand"];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSString *modelName = [user objectForKey:@"modelName"];
    if ([modelName compare:@"Histoire"] == NSOrderedSame) {
        [R_arm runAction:[SCNAction rotateByX:M_PI/4 y:0 z:M_PI/4 duration:0.2]];
        [R_elbow runAction:[SCNAction rotateByX:M_PI/8 y:-M_PI*3/4 z:M_PI/4 duration:0.2] completionHandler:^(){
            [R_hand runAction:[SCNAction rotateByX:-M_PI/2 y:-M_PI/4 z:M_PI/4 duration:0.1] completionHandler:^(){
                [R_hand runAction:[SCNAction rotateByX:0 y:0 z:-M_PI/2 duration:0.2] completionHandler:^(){
                    [R_hand runAction:[SCNAction rotateByX:0 y:0 z:M_PI/4 duration:0.1] completionHandler:^(){
                        // recover
                        [R_hand runAction:[SCNAction rotateByX:M_PI/2 y:M_PI/4 z:0 duration:0.1]];
                        [R_elbow runAction:[SCNAction rotateByX:-M_PI/8 y:M_PI*3/4 z:-M_PI/4 duration:0.2]];
                        [R_arm runAction:[SCNAction rotateByX:-M_PI/4 y:0 z:-M_PI/4 duration:0.2]];
                    }];
                }];
            }];
        }];
    } else {
        // superman sayhello
        [R_arm runAction:[SCNAction rotateByX:0 y:0 z:+M_PI/2 duration:0.1] completionHandler:^(){
            [R_hand runAction:[SCNAction rotateByX:-M_PI/2 y:0 z:0 duration:0.1]];
            [R_elbow runAction:[SCNAction rotateByX:0 y:-M_PI*5/6 z:0 duration:0.1] completionHandler:^(){
                [R_hand runAction:[SCNAction rotateByX:M_PI/4 y:0 z:0 duration:0.2] completionHandler:^(){
                    [R_hand runAction:[SCNAction rotateByX:-M_PI/2 y:0 z:0 duration:0.1] completionHandler:^(){
                        // recover
                        [R_hand runAction:[SCNAction rotateByX:+M_PI/4 y:0 z:0 duration:0.2]];
                        [R_elbow runAction:[SCNAction rotateByX:0 y:+M_PI*5/6 z:0 duration:0.2]];
                        
                        [R_hand runAction:[SCNAction rotateByX:+M_PI/2 y:0 z:0 duration:0.1]];
                        [R_arm runAction:[SCNAction rotateByX:0 y:0 z:-M_PI/2 duration:0.1]];
                    }];
                }];
            }];
        }];
    }
    
}
@end
