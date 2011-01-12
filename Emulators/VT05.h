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

class OutputChannel;
class Screen;



@interface VT05 : NSObject <Emulator> {
    unsigned _state;
    struct iPoint _dca;
    BOOL _upperCase;
}

-(void)tab: (Screen *)screen;

@end
