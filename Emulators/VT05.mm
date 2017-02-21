//
//  VT05.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/6/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

/*
 * http://vt100.net/docs/vt05-rm/contents.html
 */

#include <sys/ttydefaults.h>
#include <cctype>

#import "VT05.h"

#include "OutputChannel.h"
#include "Screen.h"


@implementation VT05

enum {
    StateText,
    StateDCAY,
    StateDCAX
};

enum {
    VTBell = 07,
    VTCursorLeft = 010,
    VTTab = 011,
    VTLineFeed = 012,
    VTCursorDown = 013,
    VTCarriageReturn = 015,
    VTCAD = 016,
    
    VTCursorRight = 030,
    VTCursorUp = 032,
    VTHome = 035,
    VTEOL = 036,
    VTEOS = 037
    
};

+(void)load
{
    [EmulatorManager registerClass: self];
}

+(NSString *)name
{
    return @"VT05";
}

-(NSString *)name
{
    return @"VT05";
}

-(const char *)termName
{
    return "vt05";
}

-(void)reset
{
    _state = StateText;
    _context.cursor = iPoint(0,0);
    _context.window = iRect(0, 0, 72, 20);
    _upperCase = YES;
    
}

-(id)init {
    if ((self = [super init])) {
        [self reset];
    }
    return self;
}

-(void)keyDown: (NSEvent *)event screen: (Screen *)screen output: (OutputChannel *)output
{
    NSEventModifierFlags flags = [event modifierFlags];
    NSString *chars = [event charactersIgnoringModifiers];
    NSUInteger length = [chars length];
    
    
    for (unsigned i = 0; i < length; ++i)
    {
        unichar uc = [chars characterAtIndex: i];
        uint8_t c;
        
        switch (uc)
        {
            case NSLeftArrowFunctionKey:
                output->write(VTCursorLeft);
                break;
            case NSRightArrowFunctionKey:
                output->write(VTCursorRight);
                break;
            case NSUpArrowFunctionKey:
                output->write(VTCursorUp);
                break;
            case NSDownArrowFunctionKey:
                output->write(VTCursorDown);
                break;
            case NSHomeFunctionKey:
                output->write(VTHome);
                break;
            case NSDeleteCharacter:
                output->write(0x7f);
                break;
            
            default:
                if (uc > 0x7f) break;
                c = uc;
                
                if (flags & NSControlKeyMask)
                {
                    c = CTRL(c);
                }
                output->write(c);
                break;
        }
    }
}


-(void)processCharacter: (uint8_t)c screen: (Screen *)screen output: (OutputChannel *)output
{

    switch (_state)
    {
        case StateText:
        {
            switch (c)
            {
                case 0x00:
                case 0x7f:
                    // padding.
                    break;
                case VTBell:
                    /*
                     * Produces an audible tone.
                     */
                    NSBeep();
                    break;
                    
                case VTCursorLeft:
                    // backspace aka left arrow.
                    if (_context.cursor.x) _context.cursor.x--;
                    break;
                
                case VTTab:
                    if (_context.cursor.x < 64) _context.cursor.x = (_context.cursor.x + 8) & ~7;
                    else if (_context.cursor.x < _context.window.maxX() -1) _context.cursor.x++;
                    break;
                    
                case VTLineFeed:
                    // line feed.
                    // only if in line 20.
                    if (_context.cursor.y == _context.window.maxY() -1)
                        screen->scrollUp();
                    break;
                    
                case VTCursorDown:
                    // arrow down.
                    if (_context.cursor.y < _context.window.maxY() -1) _context.cursor.y++;
                    break;
                
                case VTCarriageReturn:
                    // carriage return;
                    _context.cursor.x = 0;
                    break;
                
                case VTCAD:
                    // CAD
                    _state = StateDCAY;
                    break;
                
                case VTCursorRight:
                    // right arrow.
                    if (_context.cursor.x < _context.window.maxX() -1) _context.cursor.x++;
                    break;
                    
                case VTCursorUp:
                    // up arrow
                    if (_context.cursor.y) _context.cursor.y--;
                    break;
                    
                case VTHome:
                    // home
                    _context.cursor = iPoint(0,0);
                    break;
                    
                case VTEOL: {
                    // erase line (EOL)
                    // erase all data from the current cursor position 
                    // (including data in the cursor position)
                    // to end of the line.

                    iRect tmp;
                    tmp.origin = _context.cursor;
                    tmp.size = iSize(_context.window.size.width - _context.cursor.x, 1);
                    
                    screen->eraseRect(tmp);
                    
                    break;
                }
                    
                case VTEOS: {
                    // erase screen (EOS)
                    // erase all data on the crt screen from the current
                    // cursor position (including data in the cursor position)
                    // to line 20, character position 72.
                    //

                    iRect tmp;
                    tmp.origin = _context.cursor;
                    tmp.size = iSize(_context.window.size.width - _context.cursor.x, 1);
                    
                    screen->eraseRect(tmp);
                    
                    tmp = _context.window;
                    tmp.origin.y = _context.cursor.y+1;
                    tmp.size.height -= _context.cursor.y+1;
                    screen->eraseRect(tmp);
                    
                    
                    break;
                }
                    
                default:
                    if (c >= ' ' && c < 0x7f)
                    {
                        // if cursor at end of screen, overwrite previous contents, doesn't advance cursor.
                        
                        if (_upperCase) {
                            // uppercase algorithm (from vt50)
                            if (c & 0x40) c &= ~0x20;
                        }
                        screen->putc(c, _context);
                        if (_context.cursor.x < _context.window.maxX() -1) _context.cursor.x++;
                    }
                    break;
            }
        
            break;
        }

        // based on the padding requirement -after- Y component of DCA, I assume
        // the cursor is updated immediately.
        case StateDCAY:
        {
            if (c != 0x00)
            {
                c -= 32;
                if (c >= 0 || c <= _context.window.maxY()-1) _context.cursor.y = c;
                _state = StateDCAX;
            }
            break;
        }
        case StateDCAX:
        {
            if (c != 0x00) {
                c -= 32;
                if (c >= 0 || c <= _context.window.maxX()-1) _context.cursor.x = c;
                _state = StateText;
            }
            break;
        }
    }
    screen->setCursor(_context.cursor);
}


-(BOOL)resizable
{
    return NO;
}

-(struct winsize)defaultSize
{
    struct winsize ws = { 20, 72, 0, 0 };
    
    return ws;
}

@end
