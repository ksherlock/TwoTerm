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


#ifdef __cplusplus
#include <vector>
#endif

@interface VT100 : NSObject <Emulator> {

    unsigned _state;
    
    BOOL _altKeyPad;

    
    BOOL _keyMode;
    BOOL _vt52Mode;
    BOOL _graphics;
        
    iPoint _dca;
    
    
    struct __vt100flags {
        unsigned int DECANM:1;  // vt52 mode
        unsigned int DECARM:1;  // auto repeat mode.
        unsigned int DECAWM:1;  // autowrap mode
        unsigned int DECCKM:1;  // cursor key mode.
        unsigned int DECKPAM:1; // alternate keypad.
        unsigned int DECKPNM:1; // not alternate keypad.
        unsigned int DECCOLM:1; // 80/132 mode.
        unsigned int DECSCLM:1; // scrolling
        unsigned int DECSCNM:1; // screen
        unsigned int DECOM:1;   // origin
        unsigned int DECINLM:1; // interlace
        
        unsigned int LNM:1;     // line feed new line mode.
        
        
    } _flags;

#ifdef __cplusplus
    std::vector<int> _parms;
#endif
    
}


-(void)tab: (Screen *)screen;


@end
