//
//  ScanLineFilter.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScanLineFilter.h"

#import <ApplicationServices/ApplicationServices.h>


@implementation ScanLineFilter

static CIKernel *_kernel = nil;

+(void)initialize
{
    if (!_kernel)
    {
    
        NSError *err;
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *path = [bundle pathForResource: @"ScanLineFilter" ofType: @"cikernel"];
        NSString *code = [NSString stringWithContentsOfFile: path 
                                                   encoding: NSUTF8StringEncoding
                                                      error: &err];
      
        NSArray *array = [CIKernel kernelsWithString: code];
        
        _kernel = [[array objectAtIndex: 0] retain];
        
    }
}




- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithDouble:  0.00], kCIAttributeMin,
             [NSNumber numberWithDouble:  0.00], kCIAttributeMax,
             [NSNumber numberWithDouble:  0.00], kCIAttributeSliderMin,
             [NSNumber numberWithDouble:  1.00], kCIAttributeSliderMax,
             [NSNumber numberWithDouble:  0.40], kCIAttributeDefault,
             [NSNumber numberWithDouble:  0.00], kCIAttributeIdentity,
             kCIAttributeTypeDistance,           kCIAttributeType,
             nil],                               @"inputStrength",
            
            nil];
}


// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    float strength;
    CISampler *src;
    
    src = [CISampler samplerWithImage:inputImage];

    strength = [inputStrength floatValue];
    if (strength < 0) strength = 0;
    if (strength > 1.0) strength = 1.0;
    
    return [self apply: _kernel, src, [NSNumber numberWithFloat: strength], nil];
}



@end
