//
//  Apple80.h
//  2Term
//
//  Created by Kelvin Sherlock on 12/23/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Emulator.h"
#include "iGeometry.h"

@interface Apple80 : NSObject <Emulator> {

    unsigned _state;
    
    iPoint _dca;
    
}

@end
