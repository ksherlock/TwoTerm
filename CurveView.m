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

-(void)initScanLines
{
    NSMutableArray *filters;
    CIFilter *filter;
    
    [self setWantsLayer: YES];
    
    filters = [NSMutableArray arrayWithCapacity: 3];
    
    
    
    //add the scanlines (which are vertical and must therfore be rotated
    
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: [NSNumber numberWithFloat: 0.75] forKey: @"inputOpacity"];
    [filters addObject: filter];
    
    //blur it a bit...
    
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: [NSNumber numberWithFloat: 0.33] forKey: @"inputRadius"];
    
    [filters addObject: filter];
    
    [self setContentFilters: filters];
}

#define curveSize 4

- (void)drawRect:(NSRect)dirtyRect {

    NSGraphicsContext *nsgc = [NSGraphicsContext currentContext];
    CGContextRef ctx = [nsgc graphicsPort];
    
    
    NSRect bounds = [self bounds];
    
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
}
@end
