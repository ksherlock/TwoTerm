//
//  TwoTermAppDelegate.m
//  2Term
//
//  Created by Kelvin Sherlock on 6/29/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TwoTermAppDelegate.h"

#import "TermWindowController.h"
#import "NewTerminalWindowController.h"
#import "Defaults.h"
#import "VT52.h"

#import "ScanLineFilter.h"

@implementation TwoTermAppDelegate

@synthesize window;
@synthesize imageView;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    TermWindowController *controller;

    
    NSMutableArray *filters;
    NSDictionary *parameters;
    CIFilter *filter;    
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self selector: @selector(newTerminal:) name: kNotificationNewTerminal object: nil];

    
    filters = [NSMutableArray arrayWithCapacity: 3];
    
    
    //add the scanlines
    
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: [NSNumber numberWithFloat: .5] forKey: @"inputDarken"];
    [filter setValue: [NSNumber numberWithFloat: .02] forKey: @"inputLighten"];
    [filters addObject: filter];  
    
    //blur it a bit...
    
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: [NSNumber numberWithFloat: .33] forKey: @"inputRadius"];
    
    [filters addObject: filter];
    
    parameters = [NSDictionary dictionaryWithObject: filters forKey: kContentFilters];
    
    controller = [TermWindowController new];
    [controller setParameters: parameters];
    [controller showWindow: nil];
    // this leak is ok.
}

-(void)dealloc {
 
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}


-(IBAction)newDocument: (id)sender
{
    NewTerminalWindowController *controller = [NewTerminalWindowController new];

    
    [controller showWindow: nil];
    // this leak is ok.
}

#pragma mark -
#pragma mark Notificiations

-(void)newTerminal: (NSNotification *)notification
{
    
    TermWindowController *controller;
    
    NSDictionary *userInfo = [notification userInfo];

    /*
    Class klass = [userInfo objectForKey: @"Class"];
    if (![klass conformsToProtocol: @protocol(Emulator)])
        klass = [VT52 class];
    
    */
    
    controller = [TermWindowController new];
    [controller setParameters: userInfo];
    
    //[controller setEmulator: [[klass new] autorelease]];
    [controller showWindow: nil];
    // this leak is ok.
}



@end
