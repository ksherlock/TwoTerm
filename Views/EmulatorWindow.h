//
//  EmulatorWindow.h
//  2Term
//
//  Created by Kelvin Sherlock on 11/25/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
@class TextLabel;
@class CharacterGenerator;

@interface EmulatorWindow : NSWindow
{
}

@property (assign) IBOutlet TextLabel *textLabel;

-(void)setTitleTextColor: (NSColor *)color;
-(void)setTitleCharacterGenerator: (CharacterGenerator *)characterGenerator;
@end
