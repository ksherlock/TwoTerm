//
//  TextLabel.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/7/2016.
//
//

#import <Cocoa/Cocoa.h>

@interface TextLabel : NSView
{
    NSString *_text;
    NSColor *_color;
}
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSColor *color;

@end
