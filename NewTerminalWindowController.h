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
}

@property (nonatomic, assign) IBOutlet ExampleView *exampleView;

@property (nonatomic, assign) IBOutlet NSPopUpButton *terminalTypeButton;
@property (nonatomic, assign) IBOutlet NSPopUpButton *colorSchemeButton;


@property (nonatomic, assign) IBOutlet NSColorWell *foregroundColorControl;
@property (nonatomic, assign) IBOutlet NSColorWell *backgroundColorControl;



-(IBAction)cancelButton: (id)sender;
-(IBAction)connectButton: (id)sender;

-(IBAction)colorChanged: (id)sender;
-(IBAction)setColorScheme: (id)sender;


-(NSMenu *)colorMenu;

@end
