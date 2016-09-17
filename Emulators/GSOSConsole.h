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

@interface GSOSConsole : NSObject <Emulator> {
    unsigned cs;
    
    TextPort _textPort;
    
    std::vector<TextPort> _tpStack;
    
    int _scratch[4];
    
    int _cursorType;
    bool _consLF;
    bool _consDLE;
}

@end
