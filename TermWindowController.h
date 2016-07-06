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
@class ChildMonitor;

@protocol  Emulator;
    
@interface TermWindowController : NSWindowController <NSWindowDelegate> {

    NSDictionary *_parameters;
    
    EmulatorView *_emulatorView;
    CurveView *_curveView;
    
    
    
    NSObject <Emulator> *_emulator;
    
    ChildMonitor *_childMonitor;
    
    int _child;
    
    int _fd;
    pid_t _pid;
    
    dispatch_source_t _read_source;
    dispatch_source_t _wait_source;
    
}

@property (nonatomic, retain) NSDictionary *parameters;

@property (nonatomic, retain) IBOutlet ChildMonitor *childMonitor;

@property (nonatomic, retain) IBOutlet EmulatorView *emulatorView;
@property (nonatomic, retain) IBOutlet CurveView *curveView;

@property (nonatomic, retain) NSObject<Emulator> *emulator;

-(void)initPTY;

@end
