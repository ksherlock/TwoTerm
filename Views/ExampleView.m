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
@synthesize vignette = _vignette;
@synthesize bloom = _bloom;

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

    filters = [NSMutableArray arrayWithCapacity: 5];
    
    // vignette effect
    filter = [CIFilter filterWithName: @"CIVignette"];
    [filter setDefaults];
    [filter setValue: @(_vignette) forKey: @"inputIntensity"];
    [filter setValue: @(1.0) forKey: @"inputRadius"];
    
    [filters addObject: filter];
    
    
    
        
    //add the scanlines
    
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: @(_darken) forKey: @"inputDarken"];
    [filter setValue: @(_lighten) forKey: @"inputLighten"];
    [filters addObject: filter];  
    
    
    // bloom it...
    
    filter = [CIFilter filterWithName: @"CIBloom"];
    [filter setDefaults];
    [filter setValue: @2.0 forKey: @"inputRadius"];
    [filter setValue: @(_bloom) forKey: @"inputIntensity"];

    [filters addObject: filter];
    
#if 0
    //blur it a bit...
    
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: @(_blur) forKey: @"inputRadius"];
    
    [filters addObject: filter];
#endif
    

    
    [self setContentFilters: filters];   

    
}

@end
