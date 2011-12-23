//
//  EmulatorWindow.m
//  2Term
//
//  Created by Kelvin Sherlock on 11/25/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EmulatorWindow.h"
#import "TitleBarView.h"

@implementation EmulatorWindow

@synthesize titleBarView = _titleBarView;

-(id)initWithContentRect:(NSRect)contentRect 
               styleMask:(NSUInteger)styleMask 
                 backing:(NSBackingStoreType)bufferingType 
                   defer:(BOOL)flag
{

    if ((self = [super initWithContentRect: contentRect 
                                 styleMask: styleMask 
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
               styleMask:(NSUInteger)styleMask 
                 backing:(NSBackingStoreType)bufferingType 
                   defer:(BOOL)flag 
                  screen:(NSScreen *)screen
{
    
    if ((self = [super initWithContentRect: contentRect 
                                 styleMask: styleMask
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

-(void)dealloc
{
    [_titleBarView release];
    [super dealloc];
}

-(void)setTitle:(NSString *)aString
{
    [super setTitle: aString];
    [_titleBarView setTitle: aString];
}

-(void)setBackgroundColor:(NSColor *)color
{
    NSLog(@"%@", color);
    [super setBackgroundColor: color];
    [_titleBarView setColor: color];
}

-(void)awakeFromNib
{
    [self adjustTitleBar];

    //[NSApp addWindowsItem: self title: @"Window Title" filename: NO];
    //[self setHasShadow: YES];
}
/*
-(BOOL)canBecomeKeyWindow {
    return YES;
}

-(BOOL)canBecomeMainWindow {
    return YES;
}

-(BOOL)isExcludedFromWindowsMenu {
    return NO;
}
*/

-(void)adjustTitleBar
{
        
    NSView *themeView;
    NSArray *array;
    
    themeView = [[self contentView] superview];
    
    NSLog(@"%@", themeView);
    
    NSLog(@"%u", (int)[_titleBarView retainCount]);
 
    [_titleBarView setColor: [NSColor blackColor]];
    [_titleBarView setFrame: [themeView bounds]];
    [_titleBarView setTitle: [self title]];
    
    NSLog(@"%@", [self title]);
    
    array = [themeView subviews];
    
    NSLog(@"%@", array);
    
    [themeView addSubview: _titleBarView 
               positioned: NSWindowBelow 
               relativeTo: [array objectAtIndex: 0]];
    

    array = [themeView subviews];
    
    NSLog(@"%@", array);

}


@end
