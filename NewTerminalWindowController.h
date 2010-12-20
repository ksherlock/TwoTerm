//
//  NewTerminalWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 10/5/2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NewTerminalWindowController : NSWindowController <NSWindowDelegate> {
@private

    NSPopUpButton *_terminalTypeButton;
    NSButton *_scanLineButton;
    
    NSColorWell *_foregroundColorControl;
    NSColorWell *_backgroundColorControl;
    
}

@property (nonatomic, retain) IBOutlet NSPopUpButton *terminalTypeButton;
@property (nonatomic, retain) IBOutlet NSButton *scanLineButton;
@property (nonatomic, retain) IBOutlet NSColorWell *foregroundColorControl;
@property (nonatomic, retain) IBOutlet NSColorWell *backgroundColorControl;

-(IBAction)cancelButton: (id)sender;
-(IBAction)connectButton: (id)sender;



@end
