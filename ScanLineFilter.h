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
    NSNumber *inputOpacity;
    CIImage *inputImage;
}

@end
