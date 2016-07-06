//
//  ColorView.h
//  2Term
//
//  Created by Kelvin Sherlock on 12/20/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ColorView : NSView
{
    NSColor *_color;
}

@property (nonatomic, retain) NSColor *color;

@end
