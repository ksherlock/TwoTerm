//
//  EmulatorView.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "Emulator.h"

#include "iGeometry.h"

#ifdef __cplusplus

#include "Screen.h"


#endif


@class CharacterGenerator;

@interface EmulatorView : NSView {
    
    int _fd;
    
    NSObject<Emulator> *_emulator;
    
    NSThread *_readerThread;
    
    CharacterGenerator *_charGen;
    
    NSColor *_backgroundColor;
    NSColor *_foregroundColor;
    
    CGFloat _charHeight;
    CGFloat _charWidth;

    CGFloat _paddingTop;
    CGFloat _paddingBottom;
    CGFloat _paddingLeft;
    CGFloat _paddingRight;
    
    
    NSColor *_scanLine;
    
#ifdef __cplusplus
    
    Screen _screen;
    
#endif
}

-(void)startBackgroundReader;
-(void)dataAvailable;

@property (nonatomic, assign) int fd;
//@property (nonatomic, assign) iPoint cursor;

@end
