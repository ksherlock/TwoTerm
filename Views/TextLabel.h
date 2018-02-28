//
//  TextLabel.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/7/2016.
//
//

#import <Cocoa/Cocoa.h>

@class CharacterGenerator;

@interface TextLabel : NSView
{
    NSString *_text;
    NSColor *_color;
    CharacterGenerator *_generator;
}
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSColor *color;
@property (nonatomic, retain) CharacterGenerator *characterGenerator;
@end
