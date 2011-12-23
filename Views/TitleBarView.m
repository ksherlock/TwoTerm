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
@synthesize color = _color;

-(id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame: frameRect]))
    {
        [self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
        [self awakeFromNib];
    }
    
    return self;
}

-(void)awakeFromNib
{    
    _leftImage = [[NSImage imageNamed: @"titlebar-left.png"] retain];
    _rightImage = [[NSImage imageNamed: @"titlebar-right.png"] retain];
    _centerImage = [[NSImage imageNamed: @"titlebar-center.png"] retain];
    

    
    [_label setStringValue: @""];
    [_label setBackgroundColor: [NSColor clearColor]];
    [_label setTextColor: [NSColor whiteColor]];    
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
    NSAttributedString *as;
    NSDictionary *attr;
    NSShadow *shadow;
    NSMutableParagraphStyle *ps;
    
    if (!title)
    {
        [_label setStringValue: @""];
        return;
    }
    
    shadow = [NSShadow new];
    [shadow setShadowBlurRadius: 1.0];
    [shadow setShadowColor: [NSColor blackColor]];
    [shadow setShadowOffset: NSMakeSize(0.0, 1.0)];
    
    ps = [NSMutableParagraphStyle new];
    [ps setAlignment: NSCenterTextAlignment];
    [ps setLineBreakMode: NSLineBreakByTruncatingMiddle];
    
    attr = [NSDictionary dictionaryWithObjectsAndKeys: 
            shadow, NSShadowAttributeName, 
            ps, NSParagraphStyleAttributeName,
            nil];
    
    as = [[NSAttributedString alloc] initWithString: title attributes: attr]; 
    [_label setAttributedStringValue: as];

    
    [as release];
    [shadow release];
}

-(NSString *)title
{
    return [_label stringValue];
}


-(BOOL)isFlipped
{
    return YES;
}


-(void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds;


    bounds = [self bounds];
    
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(0, 0, bounds.size.width, bounds.size.height) 
                                                         xRadius: 4.0 
                                                         yRadius: 4.0];
    [path addClip];
    
    
    [_color setFill];
    NSRectFill(dirtyRect);
    
    NSDrawThreePartImage(NSMakeRect(0, 0, bounds.size.width, 24.0),_leftImage, _centerImage, _rightImage, NO, NSCompositeSourceOver, 1.0, YES);

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
