//
//  VT05.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/6/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Emulator.h"

#include "iGeometry.h"

#include "Screen.h"


@interface VT05 : NSObject <Emulator> {
    unsigned _state;
    context _context;
    BOOL _upperCase;
}

-(void)tab: (Screen *)screen;

@end
