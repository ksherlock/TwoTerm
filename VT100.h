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
    
    BOOL _keyMode;
    BOOL _vt52Mode;
    BOOL _graphics;
    
    iPoint _dca;

#ifdef __cplusplus
    std::vector<int> _parms;
#endif
    
}


@end
