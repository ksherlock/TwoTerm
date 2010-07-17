//
//  VT100.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/14/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VT100.h"

#include "Screen.h"
#include "OutputChannel.h"

#include <sys/ttydefaults.h>

@implementation VT100

#define ESC "\x1b"

enum {
    StateText,
    StateEsc,
    StateDCAY,
    StateDCAX,
    StateBracket,
    StatePound
};


-(NSString *)name
{
    return @"VT100";
}

-(const char *)termName
{
    return "vt100";
}

-(BOOL)resizable
{
    return YES;
}

-(struct winsize)defaultSize
{
    struct  winsize ws = { 24, 80, 0, 0};
    
    return ws;
}

-(void)reset
{
    _state = StateText;
    _vt52Mode = NO;
}


-(void)vt52ProcessCharacter:(uint8_t)c screen:(Screen *)screen output:(OutputChannel *)output
{
    if (_state == StateEsc)
    {
        
        switch (c)
        {
            case 0x00:
            case 0x7f:
                break;
                
            case 'A':
                // cursor up
                screen->decrementY();
                _state = StateText;
                break;
            case 'B':
                // cursor down
                screen->incrementY();
                _state = StateText;
                break;
            case 'C':
                // cursor right
                screen->incrementX();
                _state = StateText;
                break;
            case 'D':
                screen->decrementX();
                _state = StateText;
                break;
            case 'F':
                // graphics character set on
                _state = StateText;
                break;
            case 'G':
                // graphics character set off.
                _state = StateText;
                break;
            case 'H':
                // home
                screen->setCursor(0, 0);
                _state = StateText;
                break;
                
            case 'I':
                // inverse line feed.
                screen->reverseLineFeed();
                _state = StateText;
                break;
                
            case 'J':
                // erase to end of screen
                screen->eraseScreen();
                _state = StateText;
                break;
                
            case 'K':
                //erase to end of line.
                screen->eraseLine();
                _state = StateText;
                break;
                
            case 'Y':
                // dca
                _state = StateDCAY;
                break;
                
            case 'Z':
                //identify
                output->write(ESC "/Z");
                _state = StateText;
                break;
                
            case '=':
                // alt key pad
                _keyMode = YES;
                _state = StateText;
                break;
            case '>':
                _keyMode = NO;
                _state = StateText;
                break;
                
            case '1':
                // graphics on
                _state = StateText;
                break;
                
            case '2':
                // graphics off
                _state = StateText;
                break;
                
            case '<':
                // ansi mode
                _vt52Mode = NO;
                _state = StateText;
                break;
                
            default:
                NSLog(@"[%s %s]: unrecognized escape character: `%c' (%02x)", object_getClassName(self), sel_getName(_cmd), c, (int)c);
                _state = StateText;
        }
    }
    else if (_state == StateDCAY)
    {
        if (c == 0x00) return;
        _dca.y = c - 0x20;
        
        _state = StateDCAX;
    }
    else if (_state = StateDCAX)
    {
        if (c == 0x00) return;
        
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
        
        screen->setCursor(_dca, true, false);
        _state = StateText;
    }
    
}


-(void)processCharacter:(uint8_t)c screen:(Screen *)screen output:(OutputChannel *)output
{
    
    if (_vt52Mode && _state != StateText)
    {
        [self vt52ProcessCharacter: c screen: screen output: output];
        return;
    }
    
    if (_state == StateBracket)
    {
        // '[' [0-9]* CODE
        // '[' [0-9]+ (';' [0-9]+)* CODE
        
        switch (c)
        {
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                _parms.back() = _parms.back() * 10 + (c - '0');
                break;
                
            case ';':
                _parms.push_back(0);
                break;

                
            case 'A':
                // cursor up.  default 1.
            {
                int count = std::max(_parms[0], 1);
                
                screen->setY(screen->y() - count);
                
                _state = StateText;
                break;
            }
                
            case 'B':
                // cursor down.  default 1.
            {
                int count = std::max(_parms[0], 1);
                
                screen->setY(screen->y() + count);
                
                _state = StateText;
                break;
            }
                

            case 'C':
                // cursor forward.  default 1.
            {
                int count = std::max(_parms[0], 1);
                
                screen->setX(screen->x() + count);
                
                _state = StateText;
                break;
            }
                
            case 'D':
                // cursor back.  default 1.
            {
                int count = std::max(_parms[0], 1);
                
                screen->setX(screen->x() - count);
                
                _state = StateText;
                break;
            }
                
            case 'H':
            case 'f':
                // set cursor position.
                // line numbering depends on DECOM.
                //
                if (_parms.size() == 2)
                {
                    // 0 = line
                    // 1 = column
                    screen->setCursor(std::max(_parms[1], 1) - 1, std::max(_parms[1],1) - 1);
                }
                else screen->setCursor(0, 0);
                _state = StateText;
                break;
                
        }
                
        if (_state == StateText) _parms.clear();
        return;
    }
    
    if (_state == StateEsc)
    {
        switch(c)
        {
            case 0x00:
            case 0x07f:
                break;
                
            case '[':
                _state = StateBracket;
                _parms.clear();
                _parms.push_back(0);
                break;
                
            case '#':
                _state = StatePound;
                break;
            
            case 'D':
                // Index
                screen->lineFeed();
                _state = StateText;
                break;
            case 'M':
                // Reverse Index
                screen->reverseLineFeed();
                _state = StateText;
                break;
                
            case '7':
                // save cursor + attributes
            case '8':
                //restore cursor + attributes.
                _state = StateText;
                break;
         
                
                
        }
        
        
        
    }
    

    
}

static void commonKey(unichar uc, unsigned flags, Screen * screen, OutputChannel *output)
{

    switch (uc)
    {
        case NSDeleteCharacter:
            output->write(0x7f);
            break;
            
        
            
        default:
            
            if (uc <= 0x7f)
            {
                char c = uc;
                if (flags & NSControlKeyMask)
                    c = CTRL(c);
                
                output->write(c);
            }
            
    }

}

static void keyModeKey(unichar uc, unsigned flags, Screen * screen, OutputChannel *output)
{
    
    if (flags & NSNumericPadKeyMask)
    {
        const char *str = NULL;
        switch(uc)
        {
            case '0':
                str = ESC "Op";
                break;
            case '1':
                str = ESC "Oq";
                break;
            case '2':
                str = ESC "Or";
                break;
            case '3':
                str = ESC "Os";
                break;
            case '4':
                str = ESC "Ot";
                break;
            case '5':
                str = ESC "Ou";
                break;
            case '6':
                str = ESC "Ov";
                break;
            case '7':
                str = ESC "Ow";
                break;
            case '8':
                str = ESC "Ox";
                break;
            case '9':
                str = ESC "Oy";
                break;
            case ',':
                str = ESC "Ol";
                break;
            case '-':
                str = ESC "Om";
                break;
            case '.':
                str = ESC "On";
                break;
                
                
            case NSNewlineCharacter: //?
            case NSEnterCharacter:
                str = ESC "?M";
                break;
        }
        if (str)
        {
            output->write(str);
            return;
        }
    }
    
    switch(uc)
    {
        case NSUpArrowFunctionKey:
            output->write(ESC "OA");
            break;
        case NSDownArrowFunctionKey:
            output->write(ESC "OB");
            break;
        case NSRightArrowFunctionKey:
            output->write(ESC "OC");
            break;            
        case NSLeftArrowFunctionKey:
            output->write(ESC "OD");
            break;
            
            // these are located at numlock/*-
        case NSF1FunctionKey:
            output->write(ESC "OP");
            break;
        case NSF2FunctionKey:
            output->write(ESC "OQ");
            break;
        case NSF3FunctionKey:
            output->write(ESC "OR");
            break;
        case NSF4FunctionKey:
            output->write(ESC "OS");
            break;             
            
        default:
            commonKey(uc, flags, screen, output);
            break;
    }
}


static void vt52ModeKey(unichar uc, unsigned flags, Screen * screen, OutputChannel *output)
{
    if (flags & NSNumericPadKeyMask)
    {
        const char *str = NULL;
        switch(uc)
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
            case ',':
                str = ESC "?l";
                break;
            case '-':
                str = ESC "?m";
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
            return;
        }
    }
    
    switch(uc)
    {
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
            
        case NSF1FunctionKey:
            output->write(ESC "P");
            break;
        case NSF2FunctionKey:
            output->write(ESC "Q");
            break;
        case NSF3FunctionKey:
            output->write(ESC "R");
            break;
        case NSF4FunctionKey:
            output->write(ESC "S");
            break;   
            
        default:
            commonKey(uc, flags, screen, output);
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
        
        if (_vt52Mode)
            vt52ModeKey(uc, flags, screen, output);
        else if (_keyMode)
            keyModeKey(uc, flags, screen, output);
        else
            commonKey(uc, flags, screen, output);
    }

}

@end
