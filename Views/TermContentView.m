//
//  TermContentView.m
//  2Term
//
//  Created by Kelvin Sherlock on 11/26/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TermContentView.h"

@implementation TermContentView

-(void)createTrackingArea
{
    NSRect rect;
    NSRect bounds;
    
    
    if (_trackingArea)
    {
        [self removeTrackingArea: _trackingArea];
        [_trackingArea release];
        _trackingArea = nil;
    }
    
    bounds = [self bounds];
    
    rect = NSMakeRect(0, bounds.size.height - 20, bounds.size.width, 20);
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect: rect
                                                 options: NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways 
                                                   owner: self 
                                                userInfo:nil];
    
    
    [self addTrackingArea: _trackingArea];    
    
}

-(void)awakeFromNib
{    
    [super awakeFromNib];

    [self createTrackingArea];
    //[self setWantsLayer: YES];

}

-(void)updateTrackingAreas
{
    [self createTrackingArea];
}

-(void)dealloc
{
    [_trackingArea release];
    [super dealloc];
}


-(void)mouseEntered:(NSEvent *)theEvent
{
    NSLog(@"%s", sel_getName(_cmd));
    
    // animate title bar in.
}

-(void)mouseExited:(NSEvent *)theEvent
{
    NSLog(@"%s", sel_getName(_cmd));
    
    // animate title bar out.
}

@end
