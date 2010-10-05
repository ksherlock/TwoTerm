//
//  TermWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class EmulatorView;
@protocol  Emulator;
    
@interface TermWindowController : NSWindowController <NSWindowDelegate> {

    IBOutlet EmulatorView *_emulatorView;

    NSObject <Emulator> *_emulator;
    
    int _child;
    
}

@property (nonatomic, retain) NSObject<Emulator> *emulator;

-(void)initPTY;

@end
