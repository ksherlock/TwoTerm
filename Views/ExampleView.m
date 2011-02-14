//
//  ExampleView.m
//  2Term
//
//  Created by Kelvin Sherlock on 2/6/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ExampleView.h"

#import "ScanLineFilter.h"
#import "CharacterGenerator.h"

@implementation ExampleView

@synthesize lighten = _lighten;
@synthesize darken = _darken;
@synthesize blur = _blur;
@synthesize foregroundColor = _foregroundColor;


-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _foregroundColor = [[NSColor greenColor] retain];
    _charGenerator = [[CharacterGenerator generator] retain];
    [self setWantsLayer: YES];
}

- (void)dealloc
{
    [_foregroundColor release];
    [_charGenerator release];
    [super dealloc];

}

-(BOOL)isFlipped
{
    return YES;
}

-(void)drawRect:(NSRect)dirtyRect
{
    CGFloat paddingLeft = 10.0;
    CGFloat paddingTop = 10.0;
    
    const char *string = "Two Term";
    
    NSSize size = [_charGenerator characterSize];

    [super drawRect: dirtyRect];
    
    [_foregroundColor set];
    
    for (unsigned i = 0; string[i]; ++i)
    {
        [_charGenerator drawCharacter: string[i] atPoint: NSMakePoint( i * size.width + paddingLeft, paddingTop)];
    }
    
    // draw inversed on the next line.
        
    for (unsigned i = 0; string[i]; ++i)
    {
        [_foregroundColor set];        
        NSRectFill(NSMakeRect( i * size.width + paddingLeft, size.height + paddingTop, size.width, size.height));
        
        [_color set];
        [_charGenerator drawCharacter: string[i] atPoint: NSMakePoint( i * size.width + paddingLeft, size.height + paddingTop)];
    }    
}

-(void)updateEffects
{

    NSMutableArray *filters;
    CIFilter *filter;

    filters = [NSMutableArray arrayWithCapacity: 3];
        
        
    //add the scanlines
    
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: [NSNumber numberWithFloat: _darken] forKey: @"inputDarken"];
    [filter setValue: [NSNumber numberWithFloat: _lighten] forKey: @"inputLighten"];
    [filters addObject: filter];  
    
    //blur it a bit...
    
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: [NSNumber numberWithFloat: _blur] forKey: @"inputRadius"];
    
    [filters addObject: filter];
    
    
    
    [self setContentFilters: filters];   

    
}

@end
