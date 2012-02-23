//
//  CHelloWorld.m
//  GLFilter_OSX
//
//  Created by Jonathan Wight on 2/22/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CHelloWorld.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>

typedef struct Vector3 {
    GLfloat x, y, z;
    } Vector3;

@interface CHelloWorld ()

- (CGImageRef)fetchImageForTexture:(GLuint)inName width:(GLuint)inWidth height:(GLuint)inHeight CF_RETURNS_RETAINED;

@end

#pragma mark -

@implementation CHelloWorld

- (CGImageRef)run
    {
    CGLPixelFormatAttribute thePixelFormatAttributes[] = {
        kCGLPFAAccelerated,
        kCGLPFAColorSize, 8,
        kCGLPFAAlphaSize, 8,
        kCGLPFADepthSize, 16,
        0
        };
    CGLPixelFormatObj thePixelFormatObject = NULL;
    GLint theNumberOfPixelFormats = 0;
    CGLChoosePixelFormat(thePixelFormatAttributes, &thePixelFormatObject, &theNumberOfPixelFormats);
    if (thePixelFormatObject == NULL)
        {
        NSLog(@"Error: Could not choose pixel format!");
        }

    CGLContextObj theOpenGLContext = NULL;
    CGLError theError = CGLCreateContext(thePixelFormatObject, NULL, &theOpenGLContext);
    if (theError != kCGLNoError)
        {
        NSLog(@"Could not create context");
        return(NULL);
        }

    CGLSetCurrentContext(theOpenGLContext);

    // #########################################################################

    // #### Create and bind a frame buffer...
    GLuint theFramebuffer;
    glGenFramebuffers(1, &theFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, theFramebuffer);

    // #### Create a texture...
    GLuint theWorkingTexture;
    glGenTextures(1, &theWorkingTexture);
    glBindTexture(GL_TEXTURE_2D, theWorkingTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

    // #### Attach a texture to the frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, theWorkingTexture, 0);

    GLenum theStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (theStatus != GL_FRAMEBUFFER_COMPLETE)
        {
        NSLog(@"glCheckFramebufferStatus failed: %x", theStatus);
        return(NULL);
        }

    // #########################################################################

    // #### Perform some basic set up on the context...
    glViewport(0, 0, 1024, 1024);
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);

    // #########################################################################

    // #### Set a purple clear color... We shouldn't see this. But just in case
    glClearColor(1.0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // #### Draw a RED quad that covers the entire frame buffer...
    glColor4f(1.0, 0.5, 0.0, 1.0);

    glBegin(GL_QUADS);
        glVertex3f(-1.0f,-1.0f, 0.0f);
        glVertex3f(-1.0f, 1.0f, 0.0f);
        glVertex3f( 1.0f,1.0f, 0.0f);
        glVertex3f( 1.0f,-1.0f, 0.0f);
    glEnd();

    glFlush();

    // #########################################################################

    // Detatch the (old) working texture from the framebuffer

    GLuint theTexture = theWorkingTexture;
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);

    // #########################################################################

    // #### Make a new working texture...

    GLuint theNewWorkingTexture;
    glGenTextures(1, &theNewWorkingTexture);
    glBindTexture(GL_TEXTURE_2D, theNewWorkingTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

    // #### Attach a texture to the frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, theNewWorkingTexture, 0);

    theStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (theStatus != GL_FRAMEBUFFER_COMPLETE)
        {
        NSLog(@"glCheckFramebufferStatus failed: %x", theStatus);
        return(NULL);
        }

    // #########################################################################

    // ### Our framebuffer should now render to the NEW texture...

    // #########################################################################

    // #### Load our program, nothing interesting here...

    NSURL *theURL = [[NSBundle mainBundle] URLForResource:@"SimpleTexture" withExtension:@"fsh"];
    const GLchar *theSource = (const GLchar *)[[NSString stringWithContentsOfURL:theURL encoding:NSUTF8StringEncoding error:nil] UTF8String];
    GLuint theFragmentShaderName = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(theFragmentShaderName, 1, &theSource, NULL);
    glCompileShader(theFragmentShaderName);

    theURL = [[NSBundle mainBundle] URLForResource:@"SimpleTexture" withExtension:@"vsh"];
    theSource = (const GLchar *)[[NSString stringWithContentsOfURL:theURL encoding:NSUTF8StringEncoding error:nil] UTF8String];
    GLuint theVertexShaderName = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(theVertexShaderName, 1, &theSource, NULL);
    glCompileShader(theVertexShaderName);

    GLuint theProgramName = glCreateProgram();
    glAttachShader(theProgramName, theFragmentShaderName);
    glAttachShader(theProgramName, theVertexShaderName);
    glLinkProgram(theProgramName);

    theStatus = GL_FALSE;
    glGetProgramiv(theProgramName, GL_LINK_STATUS, (GLint *)&theStatus);
    if (theStatus == GL_FALSE)
        {
        NSLog(@"Failed to link");
        }

    glUseProgram(theProgramName);

    // #########################################################################

    // #### Create a buffer for the position vectors, bind it, and pass it to the GL program and then enable it...

    GLint thePositionsAttributeIndex = 0;

    glBindAttribLocation(theProgramName, thePositionsAttributeIndex, "a_position");

    const Vector3 thePositionVertices[] = {
        { -0.5, -0.5, 0 },
        { +0.5, -0.5, 0 },
        { -0.5, +0.5, 0 },
        { +0.5, +0.5, 0 },
        };

    GLuint thePositionsName;
    glGenBuffers(1, &thePositionsName);
    glBindBuffer(GL_ARRAY_BUFFER, thePositionsName);
    glBufferData(GL_ARRAY_BUFFER, sizeof(thePositionVertices), thePositionVertices, GL_STATIC_DRAW);

    glVertexAttribPointer(thePositionsAttributeIndex, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(thePositionsAttributeIndex);

    // #### Create a buffer for the tex coord vectors, bind it, and pass it to the GL program and then enable it...

    GLint theTexCoordsAttributeIndex = 1;

    glBindAttribLocation(theProgramName, theTexCoordsAttributeIndex, "a_texCoord");

    const Vector3 theTexCoordVertices[] = {
        {  0.0,  0.0 },
        { +1.0, 0.0 },
        {  0.0, +1.0 },
        { +1.0, +1.0 },
        };

    GLuint theTexCoordsName;
    glGenBuffers(1, &theTexCoordsName);
    glBindBuffer(GL_ARRAY_BUFFER, theTexCoordsName);
    glBufferData(GL_ARRAY_BUFFER, sizeof(theTexCoordVertices), theTexCoordVertices, GL_STATIC_DRAW);

    glVertexAttribPointer(theTexCoordsAttributeIndex, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glEnableVertexAttribArray(theTexCoordsAttributeIndex);

    // #### Put "theTexture" (i.e. the contents of the last render) into texture unit 0...

    GLint theTextureUniform = glGetUniformLocation(theProgramName, "u_texture0");

    glActiveTexture(GL_TEXTURE0);

    glBindTexture(GL_TEXTURE_2D, theTexture);

    glUniform1i(theTextureUniform, 0);

    // ####### This switch changes the way the fragment shader works... 0 == render texture, 1 == render gradient
    // 0 is the intended setting, 1 is only for debugging.

    GLint theSwitchUniform = glGetUniformLocation(theProgramName, "u_switch");

    #pragma mark Change this to 0 to see actual results, change it to 1 to see gradient (and prove to yourself the shader is running)
    glUniform1i(theSwitchUniform, 0);

    // #########################################################################

    // Set the clear color to blue - we WILL see this...
    glClearColor(0.0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // FIX: maybe not the best place for it, but you need this so texture2D doesn't expect mipmapped texture:
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    // Render to screen.
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glFlush();

    // You should see a RED square inside of a BLUE field.
    // Unfortunately you see a BLACK square inside of a BLUE field. It's as if the texture isn't available to the shader.

    return([self fetchImageForTexture:theNewWorkingTexture width:1024 height:1024]);
    }

- (CGImageRef)fetchImageForTexture:(GLuint)inName width:(GLuint)inWidth height:(GLuint)inHeight CF_RETURNS_RETAINED
    {
    glBindTexture(GL_TEXTURE_2D, inName);

    NSMutableData *theData = [NSMutableData dataWithLength:inWidth * 4 * inHeight];
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, theData.mutableBytes);

    CGColorSpaceRef theColorSpace = CGColorSpaceCreateDeviceRGB();

    const size_t width = inHeight;
    const size_t height = inWidth;
    const size_t bitsPerComponent = 8;
    const size_t bytesPerRow = width * (bitsPerComponent * 4) / 8;
    // TODO - probably dont want skip last
    CGBitmapInfo theBitmapInfo = kCGImageAlphaPremultipliedLast;

    CGContextRef theContext = CGBitmapContextCreateWithData(theData.mutableBytes, width, height, bitsPerComponent, bytesPerRow, theColorSpace, theBitmapInfo, NULL, NULL);

    CGImageRef theImage = CGBitmapContextCreateImage(theContext);

    // #########################################################################

    CFRelease(theContext);
    CFRelease(theColorSpace);

    return(theImage);
    }

@end
