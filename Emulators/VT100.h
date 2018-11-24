//
//  VT100.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/14/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Emulator.h"
#include "iGeometry.h"
#include "Screen.h"


#ifdef __cplusplus
#include <vector>
#include <bitset>

    struct vt100_context : public context {

        enum {
            G0, G1
        };
        enum {
            CharSet_A,
            CharSet_B,
            CharSet_0,
            CharSet_1,
            CharSet_2,
        };

        unsigned G0_charset = CharSet_B;
        unsigned G1_charset = CharSet_B;
        unsigned charset = G0;
    };

#endif

@interface VT100 : NSObject <Emulator> {

    unsigned _state;
    
    unsigned cs;
    vt100_context _context;
    Screen::CursorType _cursorType;
    BOOL _private;
    
    vt100_context _saved_context;


    
    struct __vt100flags {
        unsigned int DECANM:1;  // ANSI/vt52 mode
        unsigned int DECARM:1;  // auto repeat mode.
        unsigned int DECAWM:1;  // autowrap mode
        unsigned int DECCKM:1;  // cursor key mode.
        unsigned int DECKPAM:1; // alternate keypad.
        //unsigned int DECKPNM:1; // not alternate keypad.
        unsigned int DECCOLM:1; // 80/132 mode.
        unsigned int DECSCLM:1; // scrolling
        unsigned int DECSCNM:1; // screen
        unsigned int DECOM:1;   // origin
        unsigned int DECINLM:1; // interlace
        
        unsigned int LNM:1;     // line feed new line mode.
        
        unsigned int VT52GM:1; // vt52 graphics mode
    } _flags;

#ifdef __cplusplus
    std::vector<unsigned> _args;
    std::bitset<80> _tabs;
#endif
    
}


@end
