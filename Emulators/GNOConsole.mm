//
//  GNOConsole.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <sys/ttydefaults.h>

#include <numeric>

#import "GNOConsole.h"

#include "OutputChannel.h"
#include "Screen.h"


/*
 * The GNO Console Driver.
 * this was gleaned from the source code.
 *
 * 0x00 n/a
 * 0x01 ^A - enable overstrike mode (IODP_gInsertFlag = 0)
 * 0x02 ^B - enable insert mode (IODP_gInsertFlag = 1)
 * 0x03 ^C - setport (IODP_GotoFlag = 3)
 * 0x04 n/a
 * 0x05 ^E - turn on cursor
 * 0x06 ^F - turn off cursor
 * 0x07 ^G - beep
 * 0x08 ^H - left arrow
 * 0x09 ^I - tab
 * 0x0a ^J - Line Feed (checks IODP_Scroll)
 * 0x0b ^K - clear EOP ???? up arrow???
 * 0x0c ^L - form feed - clear screen
 * 0x0d ^M - carriage return cursor = left margin
 * 0x0e ^N - inverse off - invert flag &= 0x7fff
 * 0x0f ^O - inverse on - invert flag |= 0x8000
 * 0x10 n/a
 * 0x11 ^Q - insert line
 * 0x12 ^R - Delete Line
 * 0x13 n/a
 * 0x14 n/a
 * 0x15 ^U - right arrow
 * 0x16 ^V - scroll down 1 line
 * 0x17 ^W - scroll up 1 line
 * 0x18 ^X - mouse text off.
 * 0x19 ^Y - cursor home.
 * 0x1a ^Z - clear line
 * 0x1b ^[ - mouse text on (inv flag | 0x4000)
 * 0x1c ^\ - increment IODP_CH (kill?)
 * 0x1d ^] -clear EOL
 * 0x1e ^^ - goto xy (IODP_GotoFlag = 1)
 * 0x1f ^_ - up arrow
 *
 * mouse text only applies if mouse text and inverse are on.
 
 
 * set port - 0x03 '[' left-margin right-margin top-margin bottom-margin [any printable character]
 */


/*
 this was gleaned from the kernel reference manual.
 
 The new console driver supports all the features of the old 80-column Pascal firmware, 
 and adds a few extensions, with one exception - the codes that switched between 40 and 
 80 columns modes are not supported. It is not compatible with the GS/OS '.console' 
 driver. The control codes supported are as follows:
 
 Hex ASCII Action
 01 CTRL-A set cursor to flashing block
 02 CTRL-B set cursor to flashing underscore
 03 CTRL-C Begin "Set Text Window" sequence
 05 CTRL-E Cursor on
 06 CTRL-F Cursor off
 07 CTRL-G Perform FlexBeep
 08 CTRL-H Move left one character
 09 CTRL-I Tab
 0A CTRL-J Move down a line
 0B CTRL-K Clear to EOP (end of screen)
 0C CTRL-L Clear screen, home cursor
 0D CTRL-M Move cursor to left edge of line
 0E CTRL-N Normal text
 0F CTRL-O Inverse text
 11 CTRL-Q Insert a blank line at the current cursor position
 12 CTRL-R Delete the line at the current cursor position.
 15 CTRL-U Move cursor right one character
 16 CTRL-V Scroll display down one line
 17 CTRL-W Scroll display up one line
 18 CTRL-X Normal text, mousetext off
 19 CTRL-Y Home cursor
 1A CTRL-Z Clear entire line
 1B CTRL-[ MouseText on
 1C CTRL-\ Move cursor one character to the right
 1D CTRL-] Clear to end of line
 1E CTRL-^ Goto XY
 1F CTRL-_ Move up one line
 
 (Note: the Apple IIgs Firmware Reference incorrectly has codes 05 and 06 reversed. The 
 codes listed here are correct for both GNO/ME and the Apple IIgs 80-column firmware)
 
 The Set Text Window sequence (begun by a $03 code) works as follows:
 
 CTRL-C '[' LEFT RIGHT TOP BOTTOM
 
 CTRL-C is of course hex $03, and '[' is the open bracket character ($5B). TOP, BOTTOM, 
 LEFT, and RIGHT are single-byte ASCII values that represent the margin settings. Values 
 for TOP and BOTTOM range from 0 to 23; LEFT and RIGHT range from 0 to 79. TOP must be 
 numerically less than BOTTOM; LEFT must be less than RIGHT. Any impossible settings are 
 ignored, and defaults are used instead. The extra '[' in the sequence helps prevent the 
 screen from becoming confused in the event that random data is printed to the screen.
 
 After a successful Set Text Window sequence, only the portion of the screen inside the 
 'window' will be accessible, and only the window will scroll; any text outside the 
 window is not affected.

 */

@implementation GNOConsole





+(void)load
{
    [EmulatorManager registerClass: self];
}

+(NSString *)name
{
    return @"GNO Console";
}

-(NSString *)name
{
    return @"GNO Console";
}

-(const char *)termName
{
    return "gno-console";
}

enum {
    StateText,
    StateDCAX,
    StateDCAY,
    StateWindow1,
    StateWindow2,
    StateWindow3,
    StateWindow4,
    StateWindow5,
};

-(void)reset
{

    cs = StateText;
    _context.flags = 0;
    _context.window = iRect(0, 0, 80, 24);
    _context.cursor = iPoint(0,0);
    
    
    _cursorType = Screen::CursorTypeUnderscore;

    // set flags to plain text.
}

-(BOOL)resizable
{
    return NO;
}

-(struct winsize)defaultSize
{
    struct winsize ws = { 24, 80, 0, 0 };
    
    return ws;
}

-(void)initTerm: (struct termios *)term
{
    // Control-U is used by the up-arrow key.
    term->c_cc[VKILL] = CTRL('X');
}

-(id)init
{
    if ((self = [super init]))
    {
        [self reset];
    }
    
    return self;
}

static void forward(context &ctx, Screen *screen) {
    if (ctx.cursor.x > ctx.window.maxX()-1) {
        ctx.cursor.x = ctx.window.minX();
        if (ctx.cursor.y >= ctx.window.maxY()-1) {
            screen->scrollUp(ctx.window);
        } else ctx.cursor.y++;
    }
}

static void bs(context &ctx, Screen *screen) {
    if (ctx.cursor.x == ctx.window.minX()) {
        ctx.cursor.x = ctx.window.maxX()-1;
        if (ctx.cursor.y != ctx.window.minY()) ctx.cursor.y--;
    }
    else ctx.cursor.x--;
}

static void lf(context &ctx, Screen *screen) {
    if (ctx.cursor.y >= ctx.window.maxY()-1) {
        screen->scrollUp(ctx.window);
    } else ctx.cursor.y++;
}

-(void)processData: (uint8_t *)data length: (size_t)length screen:(Screen *)screen output:(OutputChannel *)output
{

    
    cs = std::accumulate(data, data + length, cs, [&](unsigned state, uint8_t c) -> unsigned {
        
        iPoint &cursor = _context.cursor;
        iRect &window = _context.window;
        
        c &= 0x7f;
        if (c < 0x20) {
            switch (c) {
                case CTRL('^'): return StateDCAX;
                case CTRL('C'): return StateWindow1;
                    //
                case CTRL('A'):
                    screen->setCursorType(_cursorType = Screen::CursorTypeBlock);
                    break;
                case CTRL('B'):
                    screen->setCursorType(_cursorType = Screen::CursorTypeUnderscore);
                    break;
                case CTRL('E'):
                    screen->setCursorType(_cursorType);
                    break;
                case CTRL('F'):
                    screen->setCursorType(Screen::CursorTypeNone);
                    break;
                case CTRL('G'): NSBeep(); break;
                case CTRL('H'): bs(_context, screen); break;
                case CTRL('I'): cursor.x = (cursor.x + 8) & ~0x07; forward(_context, screen); break;
                case CTRL('J'): lf(_context, screen); break;
                case CTRL('K'): {
                    // CTRL('K'):
                    // clear to end of screen
                    
                    
                    iRect tmp;
                    tmp.origin = cursor;
                    tmp.size = iSize(window.size.width - cursor.x, 1);
                    
                    screen->eraseRect(tmp);
                    
                    tmp = window;
                    tmp.origin.y = cursor.y+1;
                    tmp.size.height -= cursor.y+1;
                    screen->eraseRect(tmp);
                    break;
                }
                case CTRL('L'): {
                    // CTRL('L'):
                    // clear screen, go home.
                    screen->eraseRect(window);
                    cursor = window.origin;
                    break;
                }
                case CTRL('M'): cursor.x = window.minX(); break;
                case CTRL('N'): _context.clearFlagBit(Screen::FlagInverse); break;
                case CTRL('O'): _context.setFlagBit(Screen::FlagInverse); break;
                case CTRL('Q'): {
                    // CTRL('Q'):
                    // insert line.
                    iRect tmp(iPoint(window.minX(), cursor.y), window.bottomRight());
                    screen->scrollDown(tmp);
                    break;
                }
                case CTRL('R'): {
                    // CTRL('R'):
                    // delete line
                    iRect tmp(iPoint(window.minX(), cursor.y), window.bottomRight());
                    screen->scrollUp(tmp);
                    break;
                }
                case CTRL('U'): {
                    forward(_context, screen);
                    cursor.x++;
                    forward(_context, screen);
                    break;
                }
                case CTRL('V'): {
                    // CTRL('V'):
                    // scroll down 1 line.
                    screen->scrollDown(window);
                    break;
                }
                case CTRL('W'): {
                    // CTRL('W'):
                    // scroll up 1 line.
                    screen->scrollUp(window);
                    break;
                }
                case CTRL('X'): _context.clearFlagBit(Screen::FlagMouseText); break;
                case CTRL('Y'): cursor = iPoint(0,0); break;
                case CTRL('Z'): {
                    // CTRL('Z'):
                    // clear entire line
                    
                    iRect tmp;
                    tmp.origin = iPoint(window.origin.x, cursor.y);
                    tmp.size = iSize(window.size.width, 1);
                    screen->eraseRect(tmp);
                    break;
                }
                case CTRL('['): _context.setFlagBit(Screen::FlagMouseText); break;
                case CTRL('\\'): cursor.x++; break;
                case CTRL(']'): {
                    // CTRL(']'):
                    // clear to end of line.
                    
                    iRect tmp;
                    tmp.origin = cursor;
                    tmp.size = iSize(window.size.width - cursor.x, 1);
                    
                    screen->eraseRect(tmp);
                    break;
                }
                case CTRL('_'): if (cursor.y != window.minY()) { cursor.y--; } break;
            }
            return state;
        }
        switch (state) {
            case StateText:
                forward(_context, screen);
                screen->putc(c, _context);
                cursor.x++;
                return state;
            case StateDCAX:
                _scratch[0] = c - 32;
                return state+1;
            case StateDCAY:
                _scratch[1] = c - 32;
                if (_scratch[0] <= window.maxX()-1) cursor.x = _scratch[0];
                cursor.y = std::min(_scratch[1], window.maxY() -1);
                return StateText;
            case StateWindow1:
                if (c!= '[') return StateText;
                return state+1;
            case StateWindow2:
            case StateWindow3:
            case StateWindow4:
            case StateWindow5:
                _scratch[state-StateWindow2] = c - 32;
                if (state != StateWindow5) return state+1;


                
                // 1.
                _scratch[1] = std::min(80-1, _scratch[1])+1;
                _scratch[3] = std::min(24-1, _scratch[3])+1;

                // n.b. GNO does check 1 -after- check 2, so left could be > right
                // (eg 90, 100 : gets clamped to 90, 80.

                // 2
                if (_scratch[0] <= _scratch[1]) {
                    _scratch[0] = 0;
                    _scratch[1] = 80;
                }
                if (_scratch[2] <= _scratch[3]) {
                    _scratch[2] = 0;
                    _scratch[3] = 24;
                }
                
                window = iRect(
                               iPoint(_scratch[0], _scratch[2]),
                               iPoint(_scratch[1], _scratch[3])
                               );

                // move the cursor to the top left
                // gnome clamps the horizontal, doesn't adjust the vertical.
                //screen->setCursor(&_textPort, iPoint(0,0));
                
                if (cursor.x < _scratch[0]) cursor.x = _scratch[0];
                if (cursor.x >= _scratch[1]) cursor.x = _scratch[1] - 1;

                return StateText;
        }
        return StateText;
    });
    
    screen->setCursor(_context.cursor);
    
}


-(void)keyDown:(NSEvent *)event screen:(Screen *)screen output:(OutputChannel *)output
{
    NSEventModifierFlags flags = [event modifierFlags];
    NSString *chars = [event charactersIgnoringModifiers];
    
    NSUInteger length = [chars length];
    
    for (unsigned i = 0; i < length; ++i)
    {
        unichar uc = [chars characterAtIndex: i];
        
        switch (uc)
        {
            case NSEnterCharacter:
                output->write(CTRL('M'));
                break;
            /*    
            case NSDeleteCharacter:
                output->write(0x7f);
                break;
            */
            
            case NSBackspaceCharacter:
                output->write(0x7f);
                break;
                
            case NSLeftArrowFunctionKey:
                output->write(CTRL('H'));
                break;
                
            case NSRightArrowFunctionKey:
                output->write(CTRL('U'));
                break;
                
            case NSUpArrowFunctionKey:
                output->write(CTRL('K'));
                break;
                
            case NSDownArrowFunctionKey:
                output->write(CTRL('J'));
                break;

                
            default:
                if (uc <= 0x7f)
                {
                    char c = uc;
                    if (flags & (NSShiftKeyMask | NSAlphaShiftKeyMask))
                    {
                        c = toupper(c);
                    }
                    if (flags & NSControlKeyMask)
                        c = CTRL(c);
                    
                    output->write(c);
                }
                break;
        }
    }
}

@end
