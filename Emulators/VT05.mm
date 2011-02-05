//
//  VT05.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/6/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
}

-(void)keyDown: (NSEvent *)event screen: (Screen *)screen output: (OutputChannel *)output
{
    unsigned flags = [event modifierFlags];
    NSString *chars = [event charactersIgnoringModifiers];
    unsigned length = [chars length];
    
    
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
                    screen->decrementX();
                    break;
                
                case VTTab:
                    [self tab: screen];
                    break;
                    
                case VTLineFeed:
                    // line feed.
                    screen->lineFeed();
                    break;
                    
                case VTCursorDown:
                    // arrow down.
                    screen->incrementY();
                    break;
                
                case VTCarriageReturn:
                    // carriage return;
                    screen->setX(0);
                    break;
                
                case VTCAD:
                    // CAD
                    _state = StateDCAY;
                    break;
                
                case VTCursorRight:
                    // right arrow.
                    screen->incrementX();
                    break;
                    
                case VTCursorUp:
                    // up arrow
                    screen->decrementY();
                    break;
                    
                case VTHome:
                    // home
                    screen->setCursor(0, 0);
                    break;
                    
                case VTEOL:
                    // erase line (EOL)
                    // erase all data from the current cursor position 
                    // (including data in the cursor position)
                    // to end of the line.
                    screen->erase(Screen::EraseLineAfterCursor);
                    break;
                    
                case VTEOS:
                    // erase screen (EOS)
                    // erase all data on the crt screen from the current
                    // cursor position (including data in the cursor position)
                    // to line 20, character position 72.
                    //
                    screen->erase(Screen::EraseAfterCursor);
                    break;
                    
                default:
                    if (c >= ' ' && c < 0x7f)
                    {
                        // if cursor at end of screen, overwrite previous contents, doesn't advance cursor.
                        
                        if (_upperCase) c = toupper(c);
                        screen->putc(c);
                    }
                    break;
            }
        
            break;
        }
        case StateDCAY:
        {
            // not sure how invalid values are handled.
            
            if (c != 0x00)
            {
                _state = StateDCAX;
                _dca.y = c - ' ';
            }
            break;
        }
        case StateDCAX:
        {
            if (c != 0x00)
            {
                _state = StateText;
                _dca.x = c - ' ';
                
                screen->setCursor(_dca);
            }
            break;
        }
    }
    
}

-(void)tab: (Screen *)screen
{
    /*
     * TAB (011_8) causes the cursor to move right to the next TAB stop each time the TAB code is received.
     * TAB stops are preset eight character spaces apart.  TAB stop locations are at characters positions 1, 9,
     * 17, 25, 33, 41, 49, 57, and 65. Once the cursor reaches character position 65, all TAB commands 
     * received thereafter will cause the cursor to move only one character position.  Once the cursor reaches 
     * character position 72, receipt of the the TAB code has no effect.
     */

    int x = screen->x();
    
    if (x >= screen->width() - 8)
    {
        screen->setX(x + 1);
    }
    else
    {
        screen->setX((x + 8) & ~7);
    }
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
