//
//  TermWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class EmulatorView;
@class CurveView;

@protocol  Emulator;
    
@interface TermWindowController : NSWindowController <NSWindowDelegate> {

    EmulatorView *_emulatorView;
    CurveView *_curveView;
    
    NSObject <Emulator> *_emulator;
    
    int _child;
    
}

@property (nonatomic, retain) IBOutlet EmulatorView *emulatorView;
@property (nonatomic, retain) IBOutlet CurveView *curveView;

@property (nonatomic, retain) NSObject<Emulator> *emulator;

-(void)initPTY;

@end
