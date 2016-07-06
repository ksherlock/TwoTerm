//
//  TermContentView.m
//  2Term
//
//  Created by Kelvin Sherlock on 11/26/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TermContentView.h"
#import "TitleBarView.h"

@implementation TermContentView
@synthesize titleBar = _titleBar;

-(void)createTrackingArea
{
    
    return;
#if 0
    NSRect rect;
    NSRect bounds;
    
    
    if (_trackingArea)
    {
        [self removeTrackingArea: _trackingArea];
        [_trackingArea release];
        _trackingArea = nil;
    }
    
    bounds = [self bounds];
    
    rect = NSMakeRect(0, bounds.size.height - 24, bounds.size.width, 24);
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect: rect
                                                 options: NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways 
                                                   owner: self 
                                                userInfo:nil];
    
    
    [self addTrackingArea: _trackingArea];    
#endif 
}

-(void)awakeFromNib
{    
    [super awakeFromNib];
    [self createTrackingArea];

}


-(void)updateTrackingAreas
{
    [self createTrackingArea];
}


-(void)dealloc
{
    [_trackingArea release];
    [_titleBar release];
    [super dealloc];
}

/*
-(void)mouseEntered:(NSEvent *)theEvent
{
    //NSLog(@"%s", sel_getName(_cmd));
    
    [_titleBar fadeIn];
    // animate title bar in.
}

-(void)mouseExited:(NSEvent *)theEvent
{
    //NSLog(@"%s", sel_getName(_cmd));
    
    [_titleBar fadeOut];
    // animate title bar out.
}
*/

@end
