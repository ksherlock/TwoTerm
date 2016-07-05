//
//  VT52.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/7/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <sys/ttydefaults.h>
#include <cctype>
#include <cstdio>

#import "VT52.h"
#include "OutputChannel.h"
#include "Screen.h"

enum {
    StateText,
    StateEsc,
    StateDCAY,
    StateDCAX
};

/*
 * TODO -- the VT50x are 12 rows but double spaced.
 *
 *
 */

// VT52 is 24 x 80 upper/lowercase.
// 50/50H is 12 * 80, uppercase only.  H has a keypad.
// The 50s only display/transmit uppercase characters and lack `~ {} characters on the keypad.
// VT55 is a VT52 with extra graphic display capabilites.
enum {
    ModelVT52,
    ModelVT50H,
    ModelVT50,
    ModelVT55
};

#define ESC "\x1b"

@implementation VT52

+(void)load
{
    [EmulatorManager registerClass: self];
}

+(NSString *)name
{
    return @"VT52";
}

-(NSString *)name
{
    switch (_model)
    {
        case ModelVT50:
            return @"VT50";
        case ModelVT50H:
            return @"VT50H";
        case ModelVT55:
            return @"VT55";
        case ModelVT52:
        default:
            return @"VT52";
    }    
}

-(const char *)termName
{
    switch (_model)
    {
        case ModelVT50:
            return "vt50";
        case ModelVT50H:
            return "vt50h";
        case ModelVT55:
            return "vt55";
        case ModelVT52:
        default:
            return "vt52";
    } 
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
        
        
        if (flags & NSNumericPadKeyMask)
        {
            if (_altKeyPad)
            {
                const char *str = NULL;
                switch (uc)
                {
                    case '0':
                        str = ESC "?p";
                        break;
                    case '1':
                        str = ESC "?q";
                        break;
                    case '2':
                        str = ESC "?r";
                        break;
                    case '3':
                        str = ESC "?s";
                        break;
                    case '4':
                        str = ESC "?t";
                        break;
                    case '5':
                        str = ESC "?u";
                        break;
                    case '6':
                        str = ESC "?v";
                        break;
                    case '7':
                        str = ESC "?w";
                        break;
                    case '8':
                        str = ESC "?x";
                        break;
                    case '9':
                        str = ESC "?y";
                        break;
                    case '.':
                        str = ESC "?n";
                        break;
                    case NSNewlineCharacter: //?
                    case NSEnterCharacter:
                        str = ESC "?M";
                        break;
                        
                }
                if (str)
                {
                    output->write(str);
                    break;
                }
            }
        }
        
        
        switch (uc)
        {
            case NSEnterCharacter:
                output->write('\r');
                break;
            case NSDeleteCharacter:
                output->write(0x7f);
                break;
            case NSUpArrowFunctionKey:
                output->write(ESC "A");
                break;
            case NSDownArrowFunctionKey:
                output->write(ESC "B");
                break;
            case NSRightArrowFunctionKey:
                output->write(ESC "C");
                break;
            case NSLeftArrowFunctionKey:
                output->write(ESC "D");
                break;
                
            // 3 function keys. (VT50H / VT52)
            case NSF1FunctionKey:
                output->write(ESC "P");
                break;
            
            case NSF2FunctionKey:
                output->write(ESC "Q");
                break;

            case NSF3FunctionKey:
                output->write(ESC "R");
                break;                
                
                
            default:
                if (uc > 0x7f) break;
                c = uc;
                
                if (flags & (NSShiftKeyMask | NSAlphaShiftKeyMask))
                {
                    c = toupper(c);
                }
                
                if (flags & NSControlKeyMask)
                {
                    c = CTRL(c);
                }
                output->write(c);
                break;
        }
    }
}

-(void)reset
{
    _state = StateText;
}

-(void)processCharacter: (uint8_t)c screen: (Screen *)screen output: (OutputChannel *)output
{
    
    switch (_state)
    {
        case StateEsc:
        {
            switch (c)
            {
                case 0x00:
                case 0x7f:
                    // filler.
                    break;
                
                case 0x1b:
                    /*
                     * If the VT50 or VT50H receives ESC ESC from the host, the second ESC will cancel the Escape Sequence ...
                     * If the VT52 receies ESC ESC, it will still be prepared to interpret rather than display the next displayable character.
                     */
                    switch (_model) {
                            
                        case ModelVT50:
                        case ModelVT50H:
                            _state = StateText;
                            break;
                    }
                    break;
                
                    // cursor control.

                case 'A':
                    /* cursor up */
                    screen->decrementY();
                    _state = StateText;
                    break;
                    
                case 'C':
                    /* cursor right */
                    screen->incrementX();
                    _state = StateText;
                    break;

                case 'B':
                    /* cursor down (not on VT50) */
                    
                    if (_model != ModelVT50)
                        screen->incrementY();
                    _state = StateText;
                    break;
                    
                case 'D':
                    /* cursor left (not on the VT50) */
                    
                    if (_model != ModelVT50)
                        screen->decrementX();
                    _state = StateText;
                    break;
                    
                case 'H':
                    /* home */
                    screen->setCursor(0, 0);
                    _state = StateText;
                    break;
                    
                case 'Y':
                    /* direct cursor addressing (not on the VT50) */
                    if (_model == ModelVT50)
                    {
                        _state = StateText;
                    }
                    else
                    {
                        _state = StateDCAY;
                    }
                    break;
                    
                    
                case 'I':
                    // reverse line feed
                    switch (_model) {
                        case ModelVT52:
                        case ModelVT55:
                            screen->reverseLineFeed();
                            break;
                    }
                    _state = StateText;
                    break;     
                    
                    
                // erasing
                case 'K':
                    // erase to end of line
                    screen->erase(Screen::EraseLineAfterCursor);
                    _state = StateText;
                    break;
                    
                case 'J':
                    // erase to end of screen.
                    screen->erase(Screen::EraseAfterCursor);
                    _state = StateText;
                    break;

                    
                    // alternate keypad mode
                case '=':
                    switch (_model) {
                        case ModelVT52:
                        case ModelVT55:
                            _altKeyPad = YES;
                            break;
                    }
                    _state = StateText;
                    break; 
                    
                    
                case '>':
                    switch (_model) {
                        case ModelVT52:
                        case ModelVT55:
                            _altKeyPad = NO;
                            break;
                    }
                    _state = StateText;
                    break;
                    

                    // graphics.
                case 'F':
                    switch (_model) {
                        case ModelVT52:
                        case ModelVT55:
                            _graphics = YES;
                            break;
                    }
                    _state = StateText;
                    break;
                    
                case 'G':
                    switch (_model) {
                        case ModelVT52:
                        case ModelVT55:
                            _graphics = NO;
                            break;
                    }
                    _state = StateText;
                    break;                    
                    
                    
                case 'Z':
                    // identify terminal.
                    // NB -- these indicate no copier.
                    switch(_model) {
                        case ModelVT50:
                            output->write(ESC "/A");
                            break;
                        case ModelVT50H:
                            output->write(ESC "/H");
                            break;
                        case ModelVT52:
                            output->write(ESC "/K");
                            break;

                        case ModelVT55:
                            output->write(ESC "/C"); // E?
                            break;

                    }
                    break;
                    
                    // hold screen unsupported.
                    
                    // ESC 1 -- (VT55) -- enter graph drawing
                    // ESC 2 -- (VT55) -- exit graph drawing
                    
                default:
                    std::fprintf(stderr, "Unrecognized escape sequence: %02x (%c)\n", (int)c, c);
                    _state = StateText;
                    break;
            }
            
         
            break;
        }
            
        case StateDCAY:
        {
            if (c == 0x00) break;
            _dca.y = c - 0x20;
            _state = StateDCAX;
            break;
        }
            
        case StateDCAX:
        {
            if (c == 0x00) break;
            
            _dca.x = c - 0x20;

            /*
             * If the line # does not specify a line that exists on the screen, the VT50H
             * will move the cursor to the bottom line of the screen.  However, the VT52 will
             * not move the cursor vertically if the vertical parameter is out of bounds.
             */
            
            /*
             * If the column number is greater than 157 and, therefore, does not specify a column
             * that exists on the screen, the cursor is moved to the rightmost column on a line on all models.
             */
             
            screen->setCursor(_dca, true, _model == ModelVT50H);
        
            _state = StateText;
            break;
        }
            
        case StateText:
        {
         
            switch(c)
            {
                case 0x00:
                case 0x7f:
                    // filler
                    break;
                case 0x1b:
                    _state = StateEsc;
                    break;
                    
                case 0x07:
                    NSBeep();
                    break;
                    
                case 0x08:
                    // backspace
                    screen->decrementX();
                    break;
                    
                case 0x09:
                    [self tab: screen];
                    break;
                    
                case 0x0a:
                    screen->lineFeed();
                    break;
                    
                case 0x0d:
                    screen->setX(0);
                    break;
                    
                case 0x0e:
                    // VT52H only -- backwards compatability with the VT05.
                    if (_model == ModelVT50H)
                        _state = StateDCAY;
                    break;
                
                default:
                    if (c >= 0x20 && c < 0x7f)
                    {
                        // VT50x cannot display anything in the range 0140--0176
                        
                        if (c >= 0140 && (_model == ModelVT50 || _model == ModelVT50H))
                            c -= 040;
    
                        screen->putc(c);
                    }
                    break;
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
    switch (_model)
    {
        case ModelVT52:
        case ModelVT55:
            return YES;
        default:
        return NO;
    }
}

-(struct winsize)defaultSize
{
    struct winsize ws = { 0, 0, 0, 0};
    
    // TODO -- although VT50x have 12 rows, they are double spaced.
    
    switch (_model)
    {
        case ModelVT52:
        case ModelVT55:
            ws.ws_row = 24;
            ws.ws_col = 80;
            break;
            
        default:
            ws.ws_row = 12;
            ws.ws_col = 80;
            break;
    }
    
    return ws;
    
}


@end
