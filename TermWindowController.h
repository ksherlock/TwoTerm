//
//  TermWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <atomic>

@class EmulatorView;
@class ColorView;

@protocol  Emulator;
    
@interface TermWindowController : NSWindowController <NSWindowDelegate, NSPopoverDelegate> {
    
    IBOutlet EmulatorView *_emulatorView;
    IBOutlet ColorView *_colorView;
    
    
    NSObject <Emulator> *_emulator;
    
    /* popover configuration options */
    IBOutlet NSColorWell *_fg;
    IBOutlet NSColorWell *_bg;

    IBOutlet NSButton *_effectsButton;
    IBOutlet NSSlider *_blurSlider;
    IBOutlet NSSlider *_lightenSlider;
    IBOutlet NSSlider *_darkenSlider;
    IBOutlet NSSlider *_bloomSlider;
    IBOutlet NSSlider *_vignetteSlider;
}

@property (nonatomic, retain) IBOutlet NSViewController *popoverViewController;
@property (nonatomic, retain) IBOutlet NSPopover *popover;


@property (nonatomic, retain) NSObject<Emulator> *emulator;

@property (nonatomic, assign) BOOL effectsEnabled;
@property (nonatomic, assign) double blurValue;
@property (nonatomic, assign) double bloomValue;
@property (nonatomic, assign) double backlightValue;
@property (nonatomic, assign) double scanlineValue;
@property (nonatomic, assign) double vignetteValue;

@property (nonatomic, retain) NSColor *foregroundColor;
@property (nonatomic, retain) NSColor *backgroundColor;


-(void)initPTY;
-(void)childFinished: (int)status;
-(void)processData: (const void *)buffer size: (size_t)size;

-(void)setParameters: (NSDictionary *)parameters;

-(IBAction)resetTerminal: (id)sender;
-(IBAction)hardResetTerminal: (id)sender;

@end


@interface TermWindowController (Config)

- (IBAction)configure: (id)sender;

- (IBAction)foregroundColor:(id)sender;
- (IBAction)backgroundColor:(id)sender;
- (IBAction)swapColors:(id)sender;

- (IBAction)filterParameterChanged: (id)sender;

-(void) updateBackgroundColor;
-(void) updateForegroundColor;

-(NSArray *)effectsFilter;

@end
