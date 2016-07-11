//
//  GNOConsole.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <sys/ttydefaults.h>


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

enum  {
    StateText,
    
    StateDCAX,
    StateDCAY,

    StateSetPort1,
    StateSetPort2,
    StateSetPort3,
    StateSetPort4, 
    StateSetPort5
};

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


-(void)reset
{
    _state = StateText;

    _textPort.frame = iRect(0, 0, 80, 24);
    _textPort.cursor = iPoint(0,0);
    
    _textPort.scroll = true;
    _textPort.advanceCursor = true;
    _textPort.leftMargin = TextPort::MarginWrap;
    _textPort.rightMargin = TextPort::MarginWrap;
    
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

-(void)processCharacter:(uint8_t)c screen:(Screen *)screen output:(OutputChannel *)output
{

    if (_state == StateText)
    {
        switch (c)
        {
            case CTRL('A'):
                // set cursor to flashing block.
                _cursorType = Screen::CursorTypeBlock;
                screen->setCursorType((Screen::CursorType)_cursorType);
                break;
            case CTRL('B'):
                _cursorType = Screen::CursorTypeUnderscore;
                screen->setCursorType((Screen::CursorType)_cursorType);
                // set cursor to flashing underscore.
                break;
            
            case CTRL('C'):
                // begin set text window sequence
                _state = StateSetPort1;
                break;
            
            case CTRL('E'):
                // cursor on
                screen->setCursorType((Screen::CursorType)_cursorType);                
                break;
            
            case CTRL('F'):
                //cursor off
                screen->setCursorType(Screen::CursorTypeNone);
                break;
                
            case CTRL('G'):
                NSBeep();
                break;
                
            case CTRL('H'):
                screen->decrementX(&_textPort);
                //screen->decrementX(true);
                break;
                
            case CTRL('I'):
                // tab
                screen->tabTo(&_textPort, (_textPort.cursor.x + 8) & ~0x07);
                //screen->tabTo((screen->x() + 8) & ~0x07);
                break;
            
            case CTRL('J'):
                // down 1 line.
                screen->lineFeed(&_textPort);
                break;
            
            case CTRL('K'):
                // clear to end of screen
                screen->erase(&_textPort, Screen::EraseAfterCursor);
                break;
                
            case CTRL('L'):
                // clear screen, go home.
                screen->erase(&_textPort, Screen::EraseAll);
                screen->setCursor(&_textPort, 0, 0);
                break;
                
            case CTRL('M'):
                // move to left edge.
                screen->setX(&_textPort, 0);
                break;
                
            case CTRL('N'):
                // normal text.
                screen->clearFlagBit(Screen::FlagInverse);
                break;
            
            case CTRL('O'):
                // inverse text.
                screen->setFlagBit(Screen::FlagInverse);
                break;
                
            case CTRL('Q'):
                // insert line.
                // TODO -- verify textPort
                screen->insertLine(&_textPort, _textPort.cursor.y);
                break;
                
            case CTRL('R'):
                // delete line
                // TODO -- verify textPort
                screen->deleteLine(&_textPort, _textPort.cursor.y);
                break;
                
            case CTRL('U'):
                // right arrow.
                screen->incrementX(&_textPort);
                break;
            
            case CTRL('V'):
                // scroll down 1 line.
                screen->insertLine(&_textPort, 0);
                break;
            case CTRL('W'):
                // scroll up 1 line.
                screen->deleteLine(&_textPort, 0);
                break;
            
            case CTRL('X'):
                //mouse text off
                screen->clearFlagBit(Screen::FlagMouseText);
                break;
            
            case CTRL('Y'):
                // cursor home
                screen->setCursor(&_textPort, 0, 0);
                break;
                
            case CTRL('Z'):
                // clear entire line
                screen->erase(&_textPort, Screen::EraseLineAll);
                break;
            
            case CTRL('['):
                // mouse text on
                // inverse must also be on.
                screen->setFlagBit(Screen::FlagMouseText);
                break;
            
            case CTRL('\\'):
                // move cursor 1 character to the right
                screen->incrementX(&_textPort);
                break;
                
            case CTRL(']'):
                // clear to end of line.
                screen->erase(&_textPort, Screen::EraseLineAfterCursor);
                break;
            
            case CTRL('^'):
                // goto x y
                _state = StateDCAX;
                break;
            
            case CTRL('_'):
                // move up 1 line
                screen->decrementY(&_textPort);
                break;
                
            default:
                if (c >= 0x20 && c < 0x7f)
                {
                    screen->putc(&_textPort, c);
                }
                break;
                
        }
        
        return;
    }
    
    switch (_state)
    {
        case StateDCAX:
            _dca.x = c - 32;
            _state = StateDCAY;
            break;

        case StateDCAY:
            _dca.y = c - 32;
            screen->setCursor(&_textPort, _dca);
            
            _state = StateText;
            break;
    
        case StateSetPort1:
            // [
            if (c == '[')
            {
                _state++;
            }
            else
            {
                _state = StateText;
            }
            break;
        
        case StateSetPort2:
            // left
            _vp[0] = c - 32;
            _state++;
            break;
        
        case StateSetPort3:
            // right
            _vp[1] = c - 32 + 1;
            _state++;
            break;
        
        case StateSetPort4:
            // top
            _vp[2] = c - 32;
            _state++;
            break;
        case StateSetPort5:
            // bottom
            // and validation.
            
            _vp[3] = c - 32 + 1;
            
            _vp[0] = std::max(0, _vp[0]);
            _vp[2] = std::max(0, _vp[2]);
            
            
            _vp[1] = std::min(80, _vp[1]);
            _vp[3] = std::min(24, _vp[3]);
            

            if (_vp[1] <= _vp[0]) _vp[1] = 80;
            if (_vp[3] <= _vp[2]) _vp[3] = 24;
            

            _textPort.frame = iRect(_vp[0], _vp[2], _vp[1] - _vp[0], _vp[3] - _vp[2]);
            

            
            // move the cursor to the top left
            // gnome clamps the horizontal, doesn't adjust the vertical.
            screen->setCursor(&_textPort, iPoint(0,0));

            
            _state = StateText;
            
    }
    
    
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
