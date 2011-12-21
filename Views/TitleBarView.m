//
//  TitleBarView.m
//  2Term
//
//  Created by Kelvin Sherlock on 11/26/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TitleBarView.h"

#import <QuartzCore/QuartzCore.h>

@implementation TitleBarView
@synthesize label = _label;

-(void)awakeFromNib
{
    [_label setTextColor: [NSColor whiteColor]];
    [self setContentFilters: [NSArray array]];
    
    _leftImage = [[NSImage imageNamed: @"titlebar-left.png"] retain];
    _rightImage = [[NSImage imageNamed: @"titlebar-right.png"] retain];
    _centerImage = [[NSImage imageNamed: @"titlebar-center.png"] retain];
    
    [self setWantsLayer: YES];
    [[self layer] setOpacity: 0.0];
    
}

-(void)dealloc
{
    [_leftImage release];
    [_rightImage release];
    [_centerImage release];
    [_label release];
}

-(void)setTitle:(NSString *)title
{
    [_label setStringValue: title];
}

-(NSString *)title
{
    return [_label stringValue];
}

-(void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds;
    NSRect rect;
    
    bounds = [self bounds];
    
    /*
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(0, 0, bounds.size.width, bounds.size.height * 2) 
                                                         xRadius: 5.0 yRadius: 5.0];
    [path addClip];
    */
    
    rect = NSMakeRect(0, 0, 10, 24);
    if (NSIntersectsRect(rect, dirtyRect))
        [_leftImage drawInRect: rect fromRect: NSMakeRect(0, 0, 10, 24) operation: NSCompositeSourceOver fraction: 1.0];

    
    rect = NSMakeRect(bounds.size.width - 10, 0, 10, 24);
    if (NSIntersectsRect(rect, dirtyRect))
        [_rightImage drawInRect: rect fromRect: NSMakeRect(0, 0, 10, 24) operation: NSCompositeSourceOver fraction: 1.0];
    
    
    bounds = NSInsetRect(bounds, 10, 0);
    [_centerImage drawInRect: bounds fromRect:NSMakeRect(0, 0, 1, 24) operation: NSCompositeSourceOver fraction: 1.0];
}

-(void)fadeIn
{
    /*
    NSDictionary *dict;
    NSViewAnimation *anim;
    
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
            self, NSViewAnimationTargetKey,
            NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
            nil];
    
    anim = [NSViewAnimation new];
    
    [anim setViewAnimations: [NSArray arrayWithObject: dict]];
    [anim setDuration: 1.0];
    [anim setAnimationCurve: NSAnimationEaseIn];
    
    [anim startAnimation];
    
    [anim release];    
    */
    
    [self setContentFilters: [NSArray array]];
    
    CABasicAnimation *anim;
    CALayer *layer;
    
    layer = [self layer];
    [layer setOpacity: 1.0];
    
    anim = [CABasicAnimation animationWithKeyPath: @"opacity"];
    [anim setFromValue: [NSNumber numberWithDouble: 0.0]];
    [anim setToValue: [NSNumber numberWithDouble: 1.0]];
    [anim setDuration: 0.5];
    [anim setRemovedOnCompletion: NO];
    
    [layer addAnimation: anim forKey: @"opacity"];
    
}

-(void)fadeOut
{
    /*
    NSDictionary *dict;
    NSViewAnimation *anim;
    
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
            self, NSViewAnimationTargetKey,
            NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
            nil];
    
    anim = [NSViewAnimation new];
    
    [anim setViewAnimations: [NSArray arrayWithObject: dict]];
    [anim setDuration: 1.0];
    [anim setAnimationCurve: NSAnimationEaseIn];
    
    [anim startAnimation];
    
    [anim release];
     */
    
    CABasicAnimation *anim;
    CALayer *layer;
    
    layer = [self layer];
    [layer setOpacity: 0.0];
    
    anim = [CABasicAnimation animationWithKeyPath: @"opacity"];
    [anim setFromValue: [NSNumber numberWithDouble: 1.0]];
    [anim setToValue: [NSNumber numberWithDouble: 0.0]];
    [anim setDuration: 0.5];
    [anim setRemovedOnCompletion: NO];
    
    [layer addAnimation: anim forKey: @"opacity"];
}

@end
