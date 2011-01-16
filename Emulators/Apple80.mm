//
//  Apple80.mm
//  2Term
//
//  Created by Kelvin Sherlock on 12/23/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Apple80.h"

#include <sys/ttydefaults.h>

#include "OutputChannel.h"
#include "Screen.h"

@implementation Apple80

enum  {
    StateText,
    
    StateDCAX,
    StateDCAY
};

+(void)load
{
    [EmulatorManager registerClass: self];
}

+(NSString *)name
{
    return @"Apple 80";
}

-(NSString *)name
{
    return @"Apple 80";
}

-(const char *)termName
{
    return "appleIIe";
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
            case CTRL('E'):
                // cursor on
                break;
                
            case CTRL('F'):
                //cursor off
                break;
                
            case CTRL('G'):
                // beep 1000 hz for .1 seconds.
                NSBeep();
                break;
                
            case CTRL('H'):
                // decrement x.  moves to end of previous line...
                screen->decrementX(true);
                break;
                
            case CTRL('I'):
                // tab
                screen->tabTo((screen->x() + 8) & ~0x07);
                break;
                
            case CTRL('J'):
                // down 1 line.
                screen->lineFeed();
                break;
                
            case CTRL('K'):
                // clear to end of screen
                screen->erase(Screen::EraseAfterCursor);
                break;
                
            case CTRL('L'):
                // clear screen, go home.
                screen->erase(Screen::EraseAll);
                screen->setCursor(0, 0, true, true);
                break;
                
            case CTRL('M'):
                // move to left edge.
                // IIe also did a linefeed. [?]
                screen->setX(0, true);
                break;
                
            case CTRL('N'):
                // normal text.
                screen->clearFlagBit(Screen::FlagInverse);
                break;
                
            case CTRL('O'):
                // inverse text.
                screen->setFlagBit(Screen::FlagInverse);
                break;

            case CTRL('R'):
                // 80 column mode
                break;
                
            case CTRL('U'):
                // deactivate 80 column firmware
                break;
                
            case CTRL('V'):
                // scroll down 1 line, leaving cursor at current position.
                screen->deleteLine(0);
                break;
                
            case CTRL('W'):
                // scroll up 1 line, leaving cursor at current position.
                screen->insertLine(0);
                break;
                
            case CTRL('X'):
                //mouse text off
                screen->clearFlagBit(Screen::FlagMouseText);
                break;
                
            case CTRL('Y'):
                // cursor home
                screen->setCursor(0, 0, true, true);
                break;
            case CTRL('Z'):
                // clear entire line
                screen->erase(Screen::EraseLineAll);
                break;
                

                
            case CTRL('\\'):
                // move cursor 1 character to the right
                // TODO -- should wrap to next line.
                screen->incrementX(true);
                break;
                
            case CTRL(']'):
                // clear to end of line.
                // TODO -- should also clear cursor.
                screen->erase(Screen::EraseLineAfterCursor);
                break;
                
            case CTRL('^'):
                // goto x y
                _state = StateDCAX;
                break;
                
            case CTRL('_'):
                // move up 1 line, no scroll.
                screen->decrementY(true);
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
                /*    
                 case NSDeleteCharacter:
                 output->write(0x7f);
                 break;
                 */
            
                
                // the Apple II keyboard had a delete where the backspace key was.
                // it functions as a backspace key.
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
                    
                    if (flags & (NSAlphaShiftKeyMask | NSShiftKeyMask))
                        c = toupper(c);
                    
                    if (flags & NSControlKeyMask)
                        c = CTRL(c);
                    
                    output->write(c);
                }
                break;
        }
        
        
        
    }
}

@end
