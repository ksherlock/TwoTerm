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
//#import "VT52.h"
#import "GNOConsole.h"
#import "ChildMonitor.h"
#import "ScanLineFilter.h"

@implementation TwoTermAppDelegate

@synthesize window;
@synthesize imageView;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    TermWindowController *controller;

    
    NSDictionary *parameters;
    
#if 0
    struct sigaction sa = {};
    sa.sa_handler = SIG_IGN;
    sa.sa_flags = SA_RESTART;
    sigaction(SIGCHLD, &sa, NULL);
#endif

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self selector: @selector(newTerminal:) name: kNotificationNewTerminal object: nil];

#if 0
    filters = [NSMutableArray arrayWithCapacity: 5];


    // vignette effect
    filter = [CIFilter filterWithName: @"CIVignette"];
    [filter setDefaults];
    [filter setValue: @(1.0) forKey: @"inputIntensity"];
    [filter setValue: @(1.0) forKey: @"inputRadius"];
    [filters addObject: filter];

#if 0
    //blur it a bit...
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: @(.33) forKey: @"inputRadius"];
    
    [filters addObject: filter];
#endif
    
    //add the scanlines
    
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: @(0.5) forKey: @"inputDarken"];
    //[filter setValue: @(0.02) forKey: @"inputLighten"];
    [filters addObject: filter];  
    

    
    filter = [CIFilter filterWithName: @"CIBloom"];
    [filter setDefaults];
    [filter setValue: @2.0 forKey: @"inputRadius"];
    [filter setValue: @(0.75) forKey: @"inputIntensity"];
    
#endif

    
    parameters = @{
                   kClass: [GNOConsole class],
                   //kContentFilters: filters,
                   kForegroundColor: [NSColor colorWithRed: 0.0 green: 1.0 blue: 0.6 alpha: 1.0],
                   kBackgroundColor: [NSColor colorWithRed: 0.0 green: .25 blue: .15 alpha: 1.0]
                   };

    controller = [TermWindowController new];
    [controller setParameters: parameters];
    [controller showWindow: nil];
    // this leak is ok.
}

-(void)applicationWillTerminate:(NSNotification *)notification {
    [[ChildMonitor monitor] removeAll];
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
