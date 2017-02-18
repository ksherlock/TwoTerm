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
    
    context _context;

    unsigned cs;
    int _scratch[4];
}



@end
