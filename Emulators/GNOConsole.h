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
#include "Screen.h"


@interface GNOConsole : NSObject <Emulator>
{
    unsigned cs;
    context _context;
    Screen::CursorType _cursorType;

    int _scratch[4];
}



@end
