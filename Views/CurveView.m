//
//  CurveView.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/8/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CurveView.h"
#import "ScanLineFilter.h"

@implementation CurveView

@synthesize color = _color;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)awakeFromNib
{
    _color = [[NSColor blackColor] retain];
}

/*
-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}
*/

#define curveSize 5

- (void)drawRect:(NSRect)dirtyRect {

    //NSGraphicsContext *nsgc = [NSGraphicsContext currentContext];
    //CGContextRef ctx = [nsgc graphicsPort];
    NSRect bounds = [self bounds];
        
    //[super drawRect: dirtyRect];
    
#if 0
    
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);
    
    [_color setFill];
    
    
    CGContextMoveToPoint(ctx, 0, curveSize);
    
    CGContextAddLineToPoint(ctx, 0, bounds.size.height - curveSize);
    CGContextAddQuadCurveToPoint(ctx, 0, bounds.size.height, curveSize, bounds.size.height);
    
    CGContextAddLineToPoint(ctx, bounds.size.width - curveSize, bounds.size.height);
    CGContextAddQuadCurveToPoint(ctx, bounds.size.width, bounds.size.height, bounds.size.width, bounds.size.height - curveSize);
    
    
    CGContextAddLineToPoint(ctx, bounds.size.width, curveSize);
    CGContextAddQuadCurveToPoint(ctx, bounds.size.width, 0, bounds.size.width - curveSize, 0);
    
    
    CGContextAddLineToPoint(ctx, curveSize, 0);
    
    CGContextAddQuadCurveToPoint(ctx, 0, 0, 0, curveSize);
        
    CGContextFillPath(ctx);
#else
    
    NSBezierPath *path;

    
    [[NSColor clearColor] set];
    NSRectFill(dirtyRect);
    
    
    path = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius: curveSize yRadius: curveSize];
    [path addClip];
    //path = [NSBezierPath bezierPathWithRect: dirtyRect];
    //[path addClip];
    

    [_color set];
    NSRectFill(dirtyRect);
    
#endif
    
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
