/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <UIKit/UIKit.h>

#import <QCAR/UIGLViewProtocol.h>

#import "QCARSession.h"
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
@property (nonatomic) float angleX;
@property (nonatomic, retain) SCNScene *scene;
@property (nonatomic, retain) SCNNode *cameraNode;
@property (nonatomic, retain) SCNRenderer *scnRender;
@property (nonatomic, retain) SCNNode *rootNode;

@property (nonatomic) SCNMatrix4 scaleMatrix;           // 模型大小
@property (nonatomic) SCNMatrix4 fixedPostionMatrix;    // 模型修正后的位置
@property (nonatomic) SCNMatrix4 rotMatrix;             // 模型旋转矩阵
@property (nonatomic) float fixAngleX;
@property (nonatomic) float fixAngleY;


- (id)initWithFrame:(CGRect)frame appSession:(QCARSession *) app;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (void)savePhoto;
- (void)rotateModel:(float)angle;
- (void)dance;
- (void)sayHello;
@end
