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
#include "Screen.h"

@interface AppleX : NSObject <Emulator> {

    unsigned cs;
    unsigned _columns;
    int _scratch[4];

    context _context;
}
@end

@interface Apple40 : AppleX
@end

@interface Apple80 : AppleX
@end

