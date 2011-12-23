//
//  ColorView.m
//  2Term
//
//  Created by Kelvin Sherlock on 12/20/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ColorView.h"

@implementation ColorView

@synthesize color = _color;

- (void)drawRect:(NSRect)dirtyRect
{
    [_color setFill];
    NSRectFill(dirtyRect);
}

-(void)setColor:(NSColor *)color
{
    if (_color == color) return;
    [_color release];
    _color = [color retain];
    [self setNeedsDisplay: YES];
}

-(void)dealloc
{
    [_color release];
    [super dealloc];
}

@end
