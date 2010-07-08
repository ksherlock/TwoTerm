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


@interface VT52 : NSObject <Emulator> {

    unsigned _model;

    unsigned _state;
    iPoint _dca;    
    BOOL _altKeyPad;
    BOOL _graphics;
}

-(void)tab: (Screen *)screen;

@end
