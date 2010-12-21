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
 * 0x0d ^M - carraige return cursor = left margin
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
    
    StateRepeatChar,
    StateRepeatCount,
    
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


-(void)processCharacter:(uint8_t)c screen:(Screen *)screen output:(OutputChannel *)output
{

    if (_state == StateText)
    {
        switch (c)
        {
            case CTRL('N'):
                //Set: inverse off, mousetext off.
                screen->setFlag(Screen::FlagNormal);
                break;
            case CTRL('O'):
                //Set: inverse on, mousetext off.
                screen->setFlag(Screen::FlagInverse);
                break;            
            case CTRL('P'):
                //Set inverse off, mousetext on.
                screen->setFlag(Screen::FlagMouseText);
                break;
                
                
            case CTRL('H'):
                //Move cursor left one character.
                screen->decrementX();
                break;
            case CTRL('U'):
                //Move cursor right one character.
                screen->incrementX();
                break;
            case CTRL('K'):
                //Move cursor up one line.
                screen->decrementY();
                break;
            case CTRL('J'):
                //Move cursor down one line.
                //screen->incrementY();
                screen->lineFeed();
                break;
            case CTRL('I'):
                //Move cursor to next tab stop (every 8 chars).
                screen->tabTo((screen->x() + 8) & ~0x07);
                break;
            case CTRL('A'):
                //Move cursor to beginning of line.
                screen->setX(0);
                break;
            case CTRL('B'):
                //Move cursor to end of line.
                screen->setX(screen->width() - 1);
                break;
            case CTRL('X'):
                //Move cursor to upper-left corner.
                screen->setCursor(0, 0);
                break;
            case CTRL('^'):
                // CONTROL-^, X + 32, Y + 32
                //Position cursor to the X, Y coordinates.
                _state = StateDCAX;
                break;
                
            case CTRL('M'):
                //screen->lineFeed();
                screen->setX(0);
                break;
                
                
            case CTRL('D'):
                //Delete current character (under cursor).
                // TODO -- does this shift the rest of the row?
                screen->deletec();
                break;
            case CTRL('F'):
                //Insert space at cursor.
                screen->insertc(' ');
                break;
                
            case CTRL('Z'):
                //Delete current line.
                screen->removeLine(screen->y());
                break;
            case CTRL('V'):
                //Insert blank like.
                // TODO -- verify if the line is before or after the current line,
                // TODO -- verify if x/y change
                // TODO -- verify scrolling behavior.
                screen->addLine(screen->y()); 
                break;
            case CTRL('Y'):
                //Clear to end of line.
                screen->eraseLine();
                break;
            case CTRL('W'):
                //Clear to end of screen.
                screen->eraseScreen();
                break;
            case CTRL('L'):
                //Clear the screen (and home cursor)
                screen->setCursor(0, 0);
                screen->eraseScreen();
                break;
                
                
            case CTRL('E'):
                //Inquire if using ProTERM Special Emulation
                /*
                 * When you send out [CONTROL-E] to a caller using ProTERM 
                 * Special, the caller’s ProTERM will send back [CONTROL-“]”] 
                 * (ASCII code 29). This allows a BBS to transparently 
                 * detect the use of PSE.
                 */
                output->write(29);
                break;
                
            case CTRL('R'):
                //CONTROL-R, character, count
                //Display character, count times.
                /*
                 * This allows a three character code to be used to display 
                 * multiple characters. For example, to display a window frame, 
                 * it is necessary to show the top and bottom borders which are 
                 * long lines of the same character (dashes, underlines, etc.). 
                 * To draw a 64-character line consisting of equal signs, send 
                 * [CONTROL-R = @] where “@” is the ASCII code for 64.                 
                 */
                _state = StateRepeatChar;
                break;
         
            case CTRL('G'):
                //Sound the Bell.
                NSBeep();
                break;
                
            case CTRL('T'):
                //Sound single/dual-tone for duration.
                /*
                 * The tone command has two forms. The first invokes the single-tone 
                 * generator, which produces relatively pure tones. The second 
                 * invokes the dual-tone generator, which produces some rather 
                 * interesting sounds. The three parameters, tone1, tone2, and 
                 * duration, can all take values from 1 through 127. There is 
                 * currently no known translation between pitch/duration values 
                 * and actual frequencies/times.
                 */
                //NB - parsed but ignored, for now.
                _state = StateTone1;
                break;
                
            default:
                if (c >= 0x20 && c < 0x7f)
                {
                    screen->putc(c);
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
            screen->setCursor(_dca);
            
            _state = StateText;
            break;
    
        case StateRepeatChar:
            _repeatChar = c;
            _state = StateRepeatCount;
            break;
        
        case StateRepeatCount:
            for (unsigned i = 0; i < c; ++i)
            {
                screen->putc(_repeatChar);
            }
            _state = StateText;
            break;
            
        case StateTone1:
            _state = StateTone2;
            break;
        case StateTone2:
            // CONTROL-A indicates same as tone1.
            _state = StateToneDuration;
            break;
        case StateToneDuration:
            _state = StateText;
            break;
    }
    
    
}


-(void)keyDown:(NSEvent *)event screen:(Screen *)screen output:(OutputChannel *)output
{
    unsigned flags = [event modifierFlags];
    NSString *chars = [event charactersIgnoringModifiers];
    
    unsigned length = [chars length];
    
    for (unsigned i = 0; i < length; ++i)
    {
        unichar uc = [chars characterAtIndex: i];
        
        switch (uc)
        {
            case NSEnterCharacter:
                output->write(CTRL('M'));
                break;
                
            case NSDeleteCharacter:
                output->write(0x7f);
                break;
                
            
                // backspace and left arrow use the same code, alas.
            case NSBackspaceCharacter:
                output->write(CTRL('H'));
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
                    if (flags & NSControlKeyMask)
                        c = CTRL(c);
                    
                    output->write(c);
                }
                break;
        }
        
        
        
    }
}

@end
