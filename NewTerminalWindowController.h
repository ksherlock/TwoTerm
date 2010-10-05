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

    IBOutlet NSPopUpButton *_terminalTypeButton;
}

-(IBAction)cancelButton: (id)sender;
-(IBAction)connectButton: (id)sender;



@end
