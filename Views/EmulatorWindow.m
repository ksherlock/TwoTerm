//
//  EmulatorWindow.m
//  2Term
//
//  Created by Kelvin Sherlock on 11/25/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EmulatorWindow.h"

@implementation EmulatorWindow

-(id)initWithContentRect:(NSRect)contentRect 
               styleMask:(NSUInteger)aStyle 
                 backing:(NSBackingStoreType)bufferingType 
                   defer:(BOOL)flag
{

    if ((self = [super initWithContentRect: contentRect 
                                 styleMask: NSBorderlessWindowMask 
                                   backing: bufferingType 
                                     defer: flag]))
    {
        
        [self setOpaque: NO];
        [self setAlphaValue: 1.0];
        
        // resize in 2.0 height increments to prevent jittering the scan lines.
        [self setResizeIncrements: NSMakeSize(1.0, 2.0)];
        [self setMovableByWindowBackground: YES];

        //[self setBackgroundColor: [NSColor clearColor]];
        //[self setHasShadow: NO];
        //[self setHasShadow: YES];
        
    }
    
    return self;
}

-(id)initWithContentRect:(NSRect)contentRect 
               styleMask:(NSUInteger)aStyle 
                 backing:(NSBackingStoreType)bufferingType 
                   defer:(BOOL)flag 
                  screen:(NSScreen *)screen
{
    
    if ((self = [super initWithContentRect: contentRect 
                                 styleMask: NSBorderlessWindowMask | NSResizableWindowMask
                                   backing: bufferingType 
                                     defer: flag 
                                    screen: screen]))
    {
        
        [self setOpaque: NO];
        [self setAlphaValue: 1.0];
        [self setResizeIncrements: NSMakeSize(1.0, 2.0)];
        [self setMovableByWindowBackground: YES];

        //[self setBackgroundColor: [NSColor clearColor]];
        //[self setHasShadow: NO];
        //[self setHasShadow: YES];
        
    }
    
    return self;
    
}

-(void)awakeFromNib
{
    [NSApp addWindowsItem: self title: @"Window Title" filename: NO];
    //[self setHasShadow: YES];
}

-(BOOL)canBecomeKeyWindow {
    return YES;
}

-(BOOL)canBecomeMainWindow {
    return YES;
}

-(BOOL)isExcludedFromWindowsMenu {
    return NO;
}



@end
