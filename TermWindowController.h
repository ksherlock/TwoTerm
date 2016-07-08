//
//  TermWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class EmulatorView;
@class ColorView;

@protocol  Emulator;
    
@interface TermWindowController : NSWindowController <NSWindowDelegate> {

    NSDictionary *_parameters;
    
    EmulatorView *_emulatorView;
    ColorView *_colorView;
    
    
    
    NSObject <Emulator> *_emulator;
    
    int _fd;
    pid_t _pid;
    
    dispatch_source_t _read_source;
    dispatch_source_t _wait_source;
    
}

@property (nonatomic, retain) NSDictionary *parameters;

@property (nonatomic, retain) IBOutlet EmulatorView *emulatorView;
@property (nonatomic, retain) IBOutlet ColorView *colorView;

@property (nonatomic, retain) NSObject<Emulator> *emulator;

-(void)initPTY;

@end
