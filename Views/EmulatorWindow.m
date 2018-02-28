//
//  EmulatorWindow.m
//  2Term
//
//  Created by Kelvin Sherlock on 11/25/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "EmulatorWindow.h"
#import "TextLabel.h"

@implementation EmulatorWindow

@synthesize textLabel = _textLabel;

-(void)commonInit {
    
    [self setTitleVisibility: NSWindowTitleHidden];
    [self setTitlebarAppearsTransparent: YES];
    
    [self setOpaque: NO];
    [self setAlphaValue: 1.0];
    
    // resize in 2.0 height increments to prevent jittering the scan lines.
    [self setResizeIncrements: NSMakeSize(1.0, 2.0)];
    [self setMovableByWindowBackground: YES];
}

-(id)initWithContentRect:(NSRect)contentRect
               styleMask:(NSWindowStyleMask)styleMask
                 backing:(NSBackingStoreType)bufferingType 
                   defer:(BOOL)flag
{

    if ((self = [super initWithContentRect: contentRect 
                                 styleMask: styleMask 
                                   backing: bufferingType 
                                     defer: flag]))
    {
        [self commonInit];
    }
    
    return self;
}


-(id)initWithContentRect:(NSRect)contentRect 
               styleMask:(NSWindowStyleMask)styleMask 
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
        [self commonInit];
    }
    
    return self;
    
}

-(void)dealloc
{
    [super dealloc];
}

-(void)setTitle:(NSString *)aString
{
    [super setTitle: aString];
    [_textLabel setText: aString];

}

-(void)setTitleTextColor: (NSColor *)color
{
    [_textLabel setColor: color];
}
-(void)setBackgroundColor:(NSColor *)color
{
    [super setBackgroundColor: color];
}

-(void)setTitleCharacterGenerator: (CharacterGenerator *)characterGenerator {
    [_textLabel setCharacterGenerator: characterGenerator];
}


-(void)awakeFromNib
{
    
    [_textLabel setText: [self title]];

}


@end
