//
//  TwoTermAppDelegate.m
//  2Term
//
//  Created by Kelvin Sherlock on 6/29/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TwoTermAppDelegate.h"

#import "TermWindowController.h"
#import "Defaults.h"
#import "VT52.h"

@implementation TwoTermAppDelegate

@synthesize window;
@synthesize imageView;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    TermWindowController *controller;

    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver: self selector: @selector(newTerminal:) name: kNotificationNewTerminal object: nil];
    
    
    controller = [TermWindowController new];
    [controller showWindow: nil];
    // this leak is ok.
}

-(void)dealloc {
 
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}


-(void)newTerminal: (NSNotification *)notification
{
    
    TermWindowController *controller;
    
    NSDictionary *userInfo = [notification userInfo];

    
    Class klass = [userInfo objectForKey: @"Class"];
    if ([klass conformsToProtocol: @protocol(Emulator)])
        klass = [VT52 class];
    

    
    controller = [TermWindowController new];
    [controller setEmulator: [[klass new] autorelease]];
    [controller showWindow: nil];
    // this leak is ok.
}



@end
