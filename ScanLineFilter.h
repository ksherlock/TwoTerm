//
//  ScanLineFilter.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/10/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>


@interface ScanLineFilter : CIFilter {
    NSNumber *inputLighten;
    NSNumber *inputDarken;
    CIImage *inputImage;
}

@end
