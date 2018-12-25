//
//  Apple3.h
//  2Term
//
//  Created by Kelvin Sherlock on 12/24/2018.
//  Copyright 2018 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Emulator.h"
#include "iGeometry.h"
#include "Screen.h"


struct iii_context : public context {
    unsigned cursor_control = 0b1101;
    unsigned fg_color = 0;
    unsigned bg_color = 0;
    unsigned mode = 2;
};

@interface Apple3 : NSObject <Emulator>
{
    unsigned cs;
    iii_context _context;
    iii_context _saved_context;
    Screen::CursorType _cursorType;    
}



@end
