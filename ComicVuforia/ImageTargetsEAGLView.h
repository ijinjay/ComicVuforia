/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <UIKit/UIKit.h>

#import <QCAR/UIGLViewProtocol.h>

#import "Texture.h"
#import "QCARSession.h"
#import "SampleApplication3DModel.h"
#import "SampleGLResourceHandler.h"

#import <SceneKit/SceneKit.h>

#define NUM_AUGMENTATION_TEXTURES 4


// EAGLView is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
@interface ImageTargetsEAGLView : UIView <UIGLViewProtocol, SampleGLResourceHandler, SCNSceneRendererDelegate> {
@private
    // OpenGL ES context
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;

    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;

    QCARSession * vapp;
}

@property (nonatomic) float angleY;
@property (nonatomic) float angleZ;
@property (nonatomic, retain) SCNScene *scene;
@property (nonatomic, retain) SCNNode *cameraNode;
@property (nonatomic, retain) SCNRenderer *scnRender;
@property (nonatomic, retain) SCNNode *ship;
@property (nonatomic) GLKQuaternion quatStart;
@property (nonatomic) GLKQuaternion quat;
@property (nonatomic) GLKMatrix4 rotMatrix;

@property (nonatomic) BOOL slerping;
@property (nonatomic) float slerpCur;
@property (nonatomic) float slerpMax;
@property (nonatomic) GLKQuaternion slerpStart;
@property (nonatomic) GLKQuaternion slerpEnd;

// Add to the private interface
@property (nonatomic) GLKVector3 anchor_position;
@property (nonatomic) GLKVector3 current_position;

- (id)initWithFrame:(CGRect)frame appSession:(QCARSession *) app;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (void)savePhoto;
@end
