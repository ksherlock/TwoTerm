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
#import "ExampleView.h"

@implementation NewTerminalWindowController

@synthesize exampleView = _exampleView;

@synthesize terminalTypeButton = _terminalTypeButton;
@synthesize colorSchemeButton = _colorSchemeButton;

@synthesize foregroundColorControl = _foregroundColorControl;
@synthesize backgroundColorControl = _backgroundColorControl;

// colors
enum {
    kCustom = 0,
    kGreenBlack,
    kBlueBlack,
    kWhiteBlue,
    kAmberBlack,
    kGreen2,
    kBlue2
};

+(id)new
{
    return [[self alloc] initWithWindowNibName: @"NewTerminal"];
    
}


- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

- (void)windowDidLoad {
    
    NSWindow *window;
    
    [super windowDidLoad];
    
    window = [self window];
    //[[window contentView] setWantsLayer: YES];
    
    //[window setAutorecalculatesContentBorderThickness: NO forEdge: NSMinYEdge];
    //[window setAutorecalculatesContentBorderThickness: NO forEdge: NSMaxYEdge];
    
    
    [_terminalTypeButton setMenu: [EmulatorManager emulatorMenu]];
    
    // set color schemes.
    [_colorSchemeButton setMenu: [self colorMenu]];
    
}

-(NSMenu *)colorMenu
{
    NSMenuItem *item;
    
    NSMenu *menu = [[NSMenu new] autorelease];
    
    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"Green Black"];
    [item setTag: kGreenBlack];
    [menu addItem: item];

    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"Blue Black"];
    [item setTag: kBlueBlack];
    [menu addItem: item];
    
    
    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"White Blue"];
    [item setTag: kWhiteBlue];
    [menu addItem: item];   
    
    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"Amber Black"];
    [item setTag: kAmberBlack];
    [menu addItem: item];    
    
    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"Green Phosphor"];
    [item setTag: kGreen2];
    [menu addItem: item];
    
    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"Blue Phosphor"];
    [item setTag: kBlue2];
    [menu addItem: item];
    
    
    
    item = [[NSMenuItem new] autorelease];
    [item setTitle: @"Custom"];
    [item setTag: kCustom];
    [menu addItem: item];    
    
    return menu;
}

#pragma mark -
#pragma mark IBActions

-(IBAction)cancelButton: (id)sender
{
    [[self window] performClose: self];
}

-(IBAction)connectButton: (id)sender
{
    
    NSMenuItem *item = [_terminalTypeButton selectedItem];
    NSUInteger tag = [item tag];
    
    Class klass = [EmulatorManager emulatorForTag: (unsigned)tag];
    
    if (klass)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity: 5];
        
        [userInfo setObject: klass forKey: kClass];
        [userInfo setObject: [_foregroundColorControl color] forKey: kForegroundColor];
        [userInfo setObject: [_backgroundColorControl color] forKey: kBackgroundColor];
        

        [nc postNotificationName: kNotificationNewTerminal object: self userInfo: userInfo];
        
    }
    
    
    [[self window] performClose: self];
}

-(IBAction)colorChanged:(id)sender
{
    [_colorSchemeButton selectItemWithTag: kCustom];
    // redraw sample...
}

-(IBAction)setColorScheme:(id)sender
{
    switch ([_colorSchemeButton selectedTag])
    {
        case kGreenBlack:
            [_foregroundColorControl setColor: [NSColor greenColor]];
            [_backgroundColorControl setColor: [NSColor blackColor]];
            break;
            
        case kBlueBlack:
            [_foregroundColorControl setColor: [NSColor colorWithCalibratedRed:0.0 green: 0.5 blue: 1.0 alpha: 1.0]];
            [_backgroundColorControl setColor: [NSColor blackColor]];
            break;

            
        case kWhiteBlue:
            [_foregroundColorControl setColor: [NSColor whiteColor]];
            [_backgroundColorControl setColor: [NSColor blueColor]];
            break;
        
        case kAmberBlack:
            [_foregroundColorControl setColor: [NSColor colorWithDeviceRed: 1.0 green: 0.5 blue: 0.0 alpha: 1.0]];
            [_backgroundColorControl setColor: [NSColor blackColor]];            
            break;
        
        case kBlue2:
            [_foregroundColorControl setColor: [NSColor colorWithDeviceRed:0.324 green:0.592 blue:0.934 alpha:1.000]];
            [_backgroundColorControl setColor: [NSColor blackColor]];
            break;

        case kGreen2:
            [_foregroundColorControl setColor: [NSColor colorWithRed: 0.0 green: 1.0 blue: 0.6 alpha: 1.0]];
            [_backgroundColorControl setColor: [NSColor blackColor]];
            break;

        case kCustom:
            break;
            
            
    }
}



#pragma mark -
#pragma mark NSWindowDelegate

-(void)windowWillClose:(NSNotification *)notification
{
    [_foregroundColorControl deactivate];
    [_backgroundColorControl deactivate];
    
    [self autorelease];
}



@end
