//
//  VT52.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/7/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Emulator.h"

#include "iGeometry.h"
#include "Screen.h"

@interface VT5x : NSObject <Emulator> {

    unsigned _model;

    unsigned cs;
    BOOL _altKeyPad;
    BOOL _graphics;
    BOOL _escape;
    context _context;
}

@end

@interface VT52 : VT5x
@end

@interface  VT50H : VT5x
@end

@interface VT50 : VT5x
@end

@interface VT55 : VT5x
@end
