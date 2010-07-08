//
//  VT52View.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EmulatorView.h"

#include <string>
#include <vector>

@interface VT52View : EmulatorView {

    BOOL _altKeyPad;
    BOOL _vt50;
    
    // terminal emulator implemented as a state machine.
    unsigned _state;
    
    // only used by child thread.
    
    std::vector<struct CursorPosition> _updates;
    
    char _yTemp[2];
}




@end


