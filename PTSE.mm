//
//  PTSE.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/9/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <sys/ttydefaults.h>


#import "PTSE.h"

#include "OutputChannel.h"
#include "Screen.h"



@implementation PTSE

enum  {
    StateText,
    
    StateDCAX,
    StateDCAY,
    
    StateRepeatChar,
    StateRepeatCount,
    
    StateTone1,
    StateTone2,
    StateToneDuration
    
};


-(const char *)termName
{
    return "proterm-special";
}

-(NSString *)name
{
    return @"Proterm Special Emulation";
}

-(void)reset
{
    _state = StateText;
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
                screen->incrementY();
                break;
            case CTRL('I'):
                //Move cursor to next tab stop (every 8 chars).
                screen->setX((screen->x() + 8) & 0x07);
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
                screen->lineFeed();
                screen->setX(0);
                break;
                
                
            case CTRL('D'):
                //Delete current character (under cursor).
                break;
            case CTRL('F'):
                //Insert space at cursor.
                break;
            case CTRL('Z'):
                //Delete current line.
                break;
            case CTRL('V'):
                //Insert blank like.
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


@end
