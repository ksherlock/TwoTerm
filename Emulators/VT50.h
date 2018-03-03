//
//  VT50.h
//  TwoTerm
//
//  Created by Kelvin Sherlock on 3/2/2018.
//

#import <Foundation/Foundation.h>

#import <Cocoa/Cocoa.h>
#import "Emulator.h"

#include "iGeometry.h"
#include "Screen.h"

@interface VT50x : NSObject <Emulator> {
    
    
    unsigned cs;
    int _scratch[2];
    context _context;
    unsigned _model;
    BOOL _altKeyPad;
    BOOL _graphics;
}

@end

@interface VT50 : VT50x
@end

@interface VT50H : VT50x
@end
