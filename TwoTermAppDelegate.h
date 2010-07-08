//
//  TwoTermAppDelegate.h
//  2Term
//
//  Created by Kelvin Sherlock on 6/29/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TwoTermAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    NSImageView *imageView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSImageView *imageView;
@end
