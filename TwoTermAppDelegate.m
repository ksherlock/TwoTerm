//
//  TwoTermAppDelegate.m
//  2Term
//
//  Created by Kelvin Sherlock on 6/29/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TwoTermAppDelegate.h"

#include "chars.h"
#import "TermWindowController.h"


@implementation TwoTermAppDelegate

@synthesize window;
@synthesize imageView;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    /*
    NSImage *image;
    CGImageRef imgRef = ImageForCharacter('A');
    
    image = [[NSImage alloc] initWithCGImage: imgRef size: CGSizeZero];
    
    [imageView setImage: image];
    [image release];
    CGImageRelease(imgRef);
    */
    
    NSWindowController * win = [TermWindowController new];
    [win showWindow: nil];
}

@end
