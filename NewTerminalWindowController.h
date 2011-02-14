//
//  NewTerminalWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 10/5/2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ExampleView;

@interface NewTerminalWindowController : NSWindowController <NSWindowDelegate> {
@private

    NSPopUpButton *_terminalTypeButton;
    NSPopUpButton *_colorSchemeButton;

    
    NSColorWell *_foregroundColorControl;
    NSColorWell *_backgroundColorControl;
    
    
    NSButton *_effectsButton;
    NSSlider *_blurSlider;
    NSSlider *_lightenSlider;
    NSSlider *_darkenSlider;

    
    ExampleView *_exampleView;
    
    BOOL _effectsEnabled;
    
}

@property (nonatomic, retain) IBOutlet ExampleView *exampleView;

@property (nonatomic, retain) IBOutlet NSPopUpButton *terminalTypeButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *colorSchemeButton;


@property (nonatomic, retain) IBOutlet NSColorWell *foregroundColorControl;
@property (nonatomic, retain) IBOutlet NSColorWell *backgroundColorControl;

@property (nonatomic, retain) IBOutlet NSButton *effectsButton;
@property (nonatomic, retain) IBOutlet NSSlider *blurSlider;
@property (nonatomic, retain) IBOutlet NSSlider *lightenSlider;
@property (nonatomic, retain) IBOutlet NSSlider *darkenSlider;

@property (nonatomic, assign) BOOL effectsEnabled;



-(IBAction)cancelButton: (id)sender;
-(IBAction)connectButton: (id)sender;

-(IBAction)colorChanged: (id)sender;
-(IBAction)setColorScheme: (id)sender;

-(IBAction)filterParameterChanged: (id)sender;

-(NSMenu *)colorMenu;

@end
