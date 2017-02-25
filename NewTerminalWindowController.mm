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

@synthesize effectsButton = _effectsButton;
@synthesize foregroundColorControl = _foregroundColorControl;
@synthesize backgroundColorControl = _backgroundColorControl;

@synthesize blurSlider = _blurSlider;
@synthesize lightenSlider = _lightenSlider;
@synthesize darkenSlider = _darkenSlider;


@synthesize effectsEnabled = _effectsEnabled;
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
    
    //[window setAutorecalculatesContentBorderThickness: NO forEdge: NSMinYEdge];
    //[window setAutorecalculatesContentBorderThickness: NO forEdge: NSMaxYEdge];
    
    [self setEffectsEnabled: YES];
    
    
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
        [userInfo setObject: [self recalcBackground] forKey: kBackgroundColor];
        
        if (_effectsEnabled)
        {
            [userInfo setObject: [_exampleView contentFilters] forKey: kContentFilters];
        }
        
        [nc postNotificationName: kNotificationNewTerminal object: self userInfo: userInfo];
        
        // post notificiation...
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
    [self filterParameterChanged: nil];
}


-(IBAction)filterParameterChanged: (id)sender
{
    
    [_exampleView setForegroundColor: [_foregroundColorControl color]];
    [_exampleView setColor: [self recalcBackground]];
    
    if (_effectsEnabled)
    {
        [_exampleView setBlur: [_blurSlider floatValue]];
        //[_exampleView setLighten: [_lightenSlider floatValue]];
        [_exampleView setDarken: [_darkenSlider floatValue]];
        [_exampleView setBloom: [_bloomSlider floatValue]];
        [_exampleView setVignette: [_vignetteSlider floatValue]];

    }
    else
    {
        [_exampleView setBlur: 0.0];
        //[_exampleView setLighten: 0.0];
        [_exampleView setDarken: 0.0];
        [_exampleView setBloom: 0.0];
        [_exampleView setVignette: 0.0];
    }
    
    [_exampleView updateEffects];
    [_exampleView setNeedsDisplay: YES];
}

-(void)setEffectsEnabled:(BOOL)effectsEnabled
{
    _effectsEnabled = effectsEnabled;
    [self filterParameterChanged: nil];
}

#pragma mark -
#pragma mark NSWindowDelegate

-(void)windowWillClose:(NSNotification *)notification
{
    [_foregroundColorControl deactivate];
    [_backgroundColorControl deactivate];
    
    [self autorelease];
}

-(NSColor *)recalcBackground {
    
    NSColor *bg = [_backgroundColorControl color];
    NSColor *fg = [_foregroundColorControl color];
    CGFloat value = [_lightenSlider doubleValue];
    
    if (_effectsEnabled) {
        bg = [bg blendedColorWithFraction: value ofColor: fg];
    }
    return bg;
}


@end
