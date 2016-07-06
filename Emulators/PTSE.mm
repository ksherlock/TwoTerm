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

+(void)load
{
    [EmulatorManager registerClass: self];
}

+(NSString *)name
{
    return @"Proterm Special Emulation";
}

-(NSString *)name
{
    return @"Proterm Special Emulation";
}

-(const char *)termName
{
    return "proterm-special";
}

-(void)reset: (Screen *)screen
{
    [self reset];

    if (screen)
    {
        screen->setFlag(Screen::FlagNormal);
        screen->setTextPort(_textPort);
        screen->erase(Screen::EraseAll);
    }
    
    
}
-(void)reset
{
    struct winsize ws = [self defaultSize];
    _state = StateText;

    _textPort.cursor = iPoint(0, 0);
    _textPort.frame = iRect(0, 0, ws.ws_col, ws.ws_row);
    
    _textPort.scroll = true;
    _textPort.advanceCursor = true;
    _textPort.clampX = true;
    _textPort.clampY = true;
    _textPort.leftMargin = TextPort::MarginWrap;
    _textPort.rightMargin = TextPort::MarginWrap;   

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

-(id)init
{
    [self reset];
    return self;
}

-(void)initTerm: (struct termios *)term
{
    // Control-U is used by the up-arrow key.
    term->c_cc[VKILL] = CTRL('X');
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
                screen->setFlag(Screen::FlagMouseText | Screen::FlagInverse);
                break;
                
                
            case CTRL('H'):
                //Move cursor left one character.
                screen->decrementX(&_textPort);
                break;
            case CTRL('U'):
                //Move cursor right one character.
                screen->incrementX(&_textPort);
                break;
            case CTRL('K'):
                //Move cursor up one line.
                screen->decrementY(&_textPort);
                break;
            case CTRL('J'):
                //Move cursor down one line.
                //screen->incrementY();
                screen->lineFeed(&_textPort);
                break;
            case CTRL('I'):
                //Move cursor to next tab stop (every 8 chars).
                screen->tabTo(&_textPort, (_textPort.cursor.x + 8) & ~0x07);
                break;
            case CTRL('A'):
                //Move cursor to beginning of line.
                screen->setX(&_textPort, 0);
                break;
            case CTRL('B'):
                //Move cursor to end of line.
                screen->setX(&_textPort, _textPort.frame.width() - 1);
                break;
            case CTRL('X'):
                //Move cursor to upper-left corner.
                screen->setCursor(&_textPort, 0, 0);
                break;
            case CTRL('^'):
                // CONTROL-^, X + 32, Y + 32
                //Position cursor to the X, Y coordinates.
                _state = StateDCAX;
                break;
                
            case CTRL('M'):
                //screen->lineFeed();
                screen->setX(&_textPort, 0);
                break;
                
                
            case CTRL('D'):
                //Delete current character (under cursor).
                // TODO -- does this shift the rest of the row? Assuming yes.
                screen->deletec(&_textPort);
                break;
            case CTRL('F'):
                //Insert space at cursor.
                // TODO -- does this wrap? Assuming no.
                screen->insertc(&_textPort, ' ');
                break;
                
            case CTRL('Z'):
                //Delete current line.
                // TODO -- textPort
                screen->deleteLine(&_textPort, _textPort.cursor.y);
                break;
            case CTRL('V'):
                //Insert blank like.
                // TODO -- verify if the line is before or after the current line,
                // TODO -- verify if x/y change
                // TODO -- verify scrolling behavior.
                // TODO -- textPort
                screen->insertLine(&_textPort, _textPort.cursor.y); 
                break;
            case CTRL('Y'):
                //Clear to end of line.
                screen->erase(&_textPort, Screen::EraseLineAfterCursor);
                break;
            case CTRL('W'):
                //Clear to end of screen.
                screen->erase(&_textPort, Screen::EraseAfterCursor);
                break;
            case CTRL('L'):
                //Clear the screen (and home cursor)
                screen->setCursor(&_textPort, 0, 0);
                screen->erase(&_textPort, Screen::EraseAll);
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
    
        case StateRepeatChar:
            _repeatChar = c;
            _state = StateRepeatCount;
            break;
        
        case StateRepeatCount:
            for (unsigned i = 0; i < c; ++i)
            {
                screen->putc(&_textPort, _repeatChar);
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
                
            case NSDeleteCharacter:
                output->write(0x7f);
                break;
                
            
                // backspace and left arrow use the same code, alas.
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
                    if (flags & NSControlKeyMask)
                        c = CTRL(c);
                    
                    output->write(c);
                }
                break;
        }
        
        
        
    }
}

@end
