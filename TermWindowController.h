//
//  TermWindowController.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class EmulatorView;

@interface TermWindowController : NSWindowController {

    IBOutlet EmulatorView *_emulatorView;

    int _child;
    
}

-(void)initPTY;

@end
