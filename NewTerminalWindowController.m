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

@synthesize terminalTypeButton = _terminalTypeButton;
@synthesize scanLineButton = _scanLineButton;
@synthesize foregroundColorControl = _foregroundColorControl;
@synthesize backgroundColorControl = _backgroundColorControl;


+(id)new
{
    return [[self alloc] initWithWindowNibName: @"NewTerminal"];
    
}


- (void)dealloc {
    // Clean-up code here.

    [_terminalTypeButton release];
    [_backgroundColorControl release];
    [_foregroundColorControl release];
    [_scanLineButton release];
    
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
                                  klass, kClass,
                                  [NSNumber numberWithBool: [_scanLineButton intValue]], kScanLines,
                                  [_foregroundColorControl color], kForegroundColor,
                                  [_backgroundColorControl color], kBackgroundColor,
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
