//
//  PTSE.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Emulator.h"
#include "iGeometry.h"

#ifdef __cplusplus
#include "Screen.h"
#endif

@interface PTSE : NSObject <Emulator>
{
    unsigned _state;
    
    iPoint _dca;
    uint8_t _repeatChar;
 
#ifdef __cplusplus
    TextPort _textPort;
#endif
    
}



@end
