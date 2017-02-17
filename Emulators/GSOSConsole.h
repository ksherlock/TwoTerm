//
//  GSOSConsole.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/9/2016.
//
//

#import <Cocoa/Cocoa.h>

#import "Emulator.h"
#include "iGeometry.h"
#include "Screen.h"

struct gsos_context : public context {
    bool consWrap = true;
    bool consAdvance = true;
    bool consLF = true;
    bool consScroll = true;
    bool consVideo = true;
    bool consDLE = true;
    bool consMouse = false;
    uint8_t consFill = 0xa0;
};

@interface GSOSConsole : NSObject <Emulator> {

    
    gsos_context _context;
    std::vector<gsos_context> _context_stack;

    unsigned cs;
    int _scratch[4];
    int _cursorType;
}

@end
