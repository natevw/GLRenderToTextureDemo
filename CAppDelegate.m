//
//  CAppDelegate.m
//  GLFilter_OSX
//
//  Created by Jonathan Wight on 2/21/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CAppDelegate.h"

#import "CHelloWorld.h"

@interface CAppDelegate ()
@property (readwrite, nonatomic, strong) IBOutlet NSImageView *imageView;
@end

@implementation CAppDelegate

@synthesize window = _window;
@synthesize imageView = _imageView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
	{
	CHelloWorld *theSomething = [[CHelloWorld alloc] init];
	CGImageRef theCGImage = [theSomething run];
	
	NSBitmapImageRep *theBitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:theCGImage];
	NSImage *theImage = [[NSImage alloc] initWithSize:(NSSize){ CGImageGetWidth(theCGImage), CGImageGetHeight(theCGImage) }];
	[theImage addRepresentation:theBitmapImageRep];
	
	self.imageView.image = theImage;
	}


@end
