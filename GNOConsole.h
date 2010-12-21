//
//  GNOConsole.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Emulator.h"
#include "iGeometry.h"


@interface GNOConsole : NSObject <Emulator>
{
    unsigned _state;
    
    iPoint _dca;
    uint8_t _repeatChar;
    
}



@end
