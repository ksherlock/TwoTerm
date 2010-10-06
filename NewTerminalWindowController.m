//
//  NewTerminalWindowController.m
//  2Term
//
//  Created by Kelvin Sherlock on 10/5/2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "NewTerminalWindowController.h"
#import "Emulator.h"
#import "Defaults.h"

@implementation NewTerminalWindowController


+(id)new
{
    return [[self alloc] initWithWindowNibName: @"NewTerminal"];
    
}


- (void)dealloc {
    // Clean-up code here.

    //[_terminalTypeButton release];    
    
    [super dealloc];
}

- (void)windowDidLoad {
        
    [super windowDidLoad];
    
    
    [_terminalTypeButton setMenu: [EmulatorManager emulatorMenu]];
    
}



-(IBAction)cancelButton: (id)sender
{
    [[self window] performClose: self];
}

-(IBAction)connectButton: (id)sender
{
    
    NSMenuItem *item = [_terminalTypeButton selectedItem];
    unsigned tag = [item tag];
    
    Class klass = [EmulatorManager emulatorForTag: tag];
    
    if (klass)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  klass, @"Class",
                                  nil];
        
        [nc postNotificationName: kNotificationNewTerminal object: self userInfo: userInfo];
        
        // post notificiation...
    }
    
    
    [[self window] performClose: self];
}


#pragma mark -
#pragma mark NSWindowDelegate

-(void)windowWillClose:(NSNotification *)notification
{
    [self autorelease];
}

@end
