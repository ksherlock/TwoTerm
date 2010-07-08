//
//  EmulatorView.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
#include <vector>
#endif

struct CursorPosition {
#ifdef __cplusplus
    CursorPosition(int _x, int _y) throw() : x(_x), y(_y) {}
    CursorPosition() throw() : x(0), y(0) {}
    
    bool operator == (const CursorPosition& rhs) throw()
    { return rhs.x == x && rhs.y == y; }

    bool operator != (const CursorPosition& rhs) throw()
    { return ! (*this == rhs); }
    
#endif
    int x;
    int y;
};

struct CharInfo {
    char c;
    uint8_t flags;
};



@class CharacterGenerator;

@interface EmulatorView : NSView {
    int _fd;

    /* these should not be modified without locking */
    struct CursorPosition _cursor;
    struct CharInfo _screen[24][80];
    
    /* end locking */

    
    NSThread *_readerThread;
    NSLock *_lock;
    
    CharacterGenerator *_charGen;
    
    NSColor *_backgroundColor;
    NSColor *_foregroundColor;
    
    CGFloat _charHeight;
    CGFloat _charWidth;
        
    unsigned _height;
    unsigned _width;
    
    
    
#ifdef __cplusplus
    
    //std::vector< std::vector<CharInfo> > _screen;
    
#endif
}

-(void)startBackgroundReader;
-(void)dataAvailable;

@property (nonatomic, assign) int fd;
@property (nonatomic, assign) struct CursorPosition cursorPosition;

@end
