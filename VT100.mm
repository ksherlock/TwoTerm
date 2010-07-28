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
    StateBracketQuestion,
    StatePound
};


-(id)init
{
    self = [super init];
    [self reset];
    
    return self;
}
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
    
    _flags.DECANM = 1; // ansi/vt100 mode
    _flags.DECARM = 0;
    _flags.DECAWM = 0;
    _flags.DECCKM = 0;
    _flags.DECKPAM = 0;
    _flags.DECKPNM = 1;
    _flags.DECCOLM = 0;
    
    _flags.DECSCLM = 0;
    _flags.DECSCNM = 0;
    _flags.DECOM = 0;
    _flags.DECINLM = 0;
    _flags.LNM = 0;
    
    
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
                _altKeyPad = YES;
                _state = StateText;
                break;
            case '>':
                _altKeyPad = NO;
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
    
    
    if (_state == StateBracketQuestion)
    {
        // ESC [? \d+ h|l 
        switch(c)
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
            
            case 'h':
            {
                // h = set
                std::vector<int>::iterator iter;
                
                for (iter = _parms.begin(); iter != _parms.end(); ++iter)
                {
                    switch (*iter)
                    {
                            /*
                        case 20:
                            _flags.LNM = 1;
                            break;
                             */
                            
                        case 1:
                            _flags.DECCKM = 1;
                            break;
  
                        case 3:
                            _flags.DECCOLM = 1;
                            screen->setSize(132, 24);
                            break;
                            
                        case 4:
                            _flags.DECSCLM = 1;
                            break;
                        
                        case 5:
                            _flags.DECSCNM = 1;
                            break;
                            
                        case 6:
                            _flags.DECOM = 1;
                            break;
                        
                        case 7:
                            _flags.DECAWM = 1;
                            break;
                            
                        case 8:
                            _flags.DECARM = 1;
                            break;
                            
                        case 9:
                            _flags.DECINLM = 1;
                            break;
                            
                    }
                }
                _state = StateText;
                break;
            }
                
            case 'l':
            {
                
                // l = reset
                std::vector<int>::iterator iter;
                
                for (iter = _parms.begin(); iter != _parms.end(); ++iter)
                {
                    switch (*iter)
                    {
                            /*
                        case 20:
                            _flags.LNM = 0;
                            break;
                             */
                            
                        case 1:
                            _flags.DECCKM = 0;
                            break;
                            
                        case 2:
                            _vt52Mode = YES;
                            _flags.DECANM = 0;
                            break;
                            
                        case 3:
                            _flags.DECCOLM = 0;
                            screen->setSize(80, 24);
                            break;
                            
                        case 4:
                            _flags.DECSCLM = 0;
                            break;
                            
                        case 5:
                            _flags.DECSCNM = 0;
                            break;
                            
                        case 6:
                            _flags.DECOM = 0;
                            break;
                            
                        case 7:
                            _flags.DECAWM = 0;
                            break;
                            
                        case 8:
                            _flags.DECARM = 0;
                            break;
                            
                        case 9:
                            _flags.DECINLM = 0;
                            break;
                            
                    }
                }
                _state = StateText;
                break;                
                
            }
            default:
                NSLog(@"[%s %s]: unrecognized escape character: `ESC [? %d %c' (%02x)", 
                      object_getClassName(self), sel_getName(_cmd), _parms[0], c, (int)c);

                _state = StateText;
                break;
        }
        
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

            case '?':
                _parms.clear();
                _parms.push_back(0);
                _state = StateBracketQuestion;
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
             
                
            case 'J':
                /* 
                 * erase
                 * 0 J -> erase from cursor to end of screen
                 * 1 J -> erase from beginning of screen to cursor
                 * 2 J -> erase entire screen
                 */
            {
             
                switch (_parms[0])
                {
                    default:
                        screen->erase(Screen::EraseAfterCursor);
                        break;
                    case 1:
                        screen->erase(Screen::EraseBeforeCursor);
                        break;
                    case 2:
                        screen->erase(Screen::EraseAll);
                        break;

                }
                _state = StateText;
                break;
            }
                
            case 'K':
                /*
                 * erase
                 * 0 K -> erase from cursor to end of line
                 * 1 K -> erase from beginning of line to cursor
                 * 2 K -> erase entire line contaning the cursor.
                 */
            {   
                switch(_parms[0])
                {
                    default:
                        screen->erase(Screen::EraseLineAfterCursor);
                        break;
                        
                    case 1:
                        screen->erase(Screen::EraseLineBeforeCursor);
                        break;
                    case 2:
                        screen->erase(Screen::EraseLineAll);;
                        break;

                }
                _state = StateText;
                break;
            }
                
                
            case 'c':
            {
                // who are you?
                
                output->write(ESC "[?1;0c");
             
                _state = StateText;
                break;
            }
                
                
            case 'n':
                // status reports.
            {
                char *str = NULL;
             
                switch (_parms[0])
                {
                    case 5:
                        // terminal status report
                        // ESC [ 0 n == terminal ok
                        // ESC [ 3 n == terminal not ok.
                        output->write(ESC "0n");
                        break;
                        
                    case 6:
                        // cursor position
                        // ESC [ line ; column R
                        asprintf(&str, ESC "[%u;%uR", screen->y() + 1, screen->x() + 1);
                        if (str)
                        {
                            output->write(str);
                            free(str);
                        }
                        break;
                    
                    default:
                        NSLog(@"[%s %s]: unrecognized escape character: `ESC [ %d %c'", 
                              object_getClassName(self), sel_getName(_cmd), _parms[0], c);
                        break;
                     
                                      
                }
                
                _state = StateText;
                break;
            }
                
            case 'l':
            {
                // l = reset
                std::vector<int>::iterator iter;
                
                for (iter = _parms.begin(); iter != _parms.end(); ++iter)
                {
                    switch (*iter)
                    {
                             case 20:
                             _flags.LNM = 0;
                             break;
                    }
                }
                _state = StateText;
                break;
            }
                
            case 'h':
            {
                // h = set
                std::vector<int>::iterator iter;
                
                for (iter = _parms.begin(); iter != _parms.end(); ++iter)
                {
                    switch (*iter)
                    {
                        case 20:
                            _flags.LNM = 1;
                            break;
                    }
                }
                _state = StateText;
                break;
                
            }
                
                
                
            case 'm':
            {
                std::vector<int>::iterator iter;
                unsigned flag = screen->flag();
                
                for (iter = _parms.begin(); iter != _parms.end(); ++iter)
                {
                    switch (*iter)
                    {
                        case 0:
                            // attributes off
                            flag = Screen::FlagNormal;
                            break;
                        case 1:
                            // bold/increased intensity.
                            flag |=  Screen::FlagBold;
                            break;
                        case 4:
                            // underscore.
                            flag |= Screen::FlagInverse;
                            break;
                        case 5:
                            //blink
                            flag |= Screen::FlagBlink;
                            break;
                            
                        case 7:
                            // inverse
                            flag |= Screen::FlagInverse;
                            break;
                    }
                }
                
                screen->setFlag(flag);
                _state = StateText;
                
                break;
            }
                
            default:
                NSLog(@"[%s %s]: unrecognized escape character: `ESC [ %c' (%02x)", object_getClassName(self), sel_getName(_cmd), c, (int)c);
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
            
            case '=':
                _flags.DECKPAM = 1;
                _flags.DECKPNM = 0;
                _altKeyPad = YES;
                _state = StateText;
                break;
                
            case '>':
                _flags.DECKPAM = 0;
                _flags.DECKPNM = 1;
                _altKeyPad = NO;                
                _state = StateText;
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
                
            case 'Z':
                output->write(ESC "[?1;0c");
                _state = StateText;
                break;
                
            case '7':
                // save cursor + attributes
            case '8':
                //restore cursor + attributes.
                _state = StateText;
                break;
         
            default:
                NSLog(@"[%s %s]: unrecognized escape character: `ESC %c' (%02x)", object_getClassName(self), sel_getName(_cmd), c, (int)c);
                _state = StateText;
                break;
        }
   
        return;
    }
    
    if (_state == StateText)
    {
        switch (c)
        {
            case 0x00:
            case 0x7f:
                break;
            case 0x1b:
                _state = StateEsc;
                break;
            case CTRL('G'):
                NSBeep();
                break;
                
            case 0x08:
                screen->decrementX();
                break;
                
            case '\t':
                [self tab: screen];
                break;
                
            case '\n':
                screen->lineFeed();
                if (_flags.LNM)
                    screen->setX(0);
                break;
                
            case '\r':
                screen->setX(0);
                break;                
                
            default:
                if (c >= 0x20 && c < 0x7f)
                {
                    screen->putc(c);
                }
                break;
        }
    }
   
}




static void vt100ModeKey(unichar uc, unsigned flags, Screen *screen, OutputChannel *output, struct __vt100flags vt100flags)
{
    const char *str = NULL;

    
    if (vt100flags.DECKPAM && (flags & NSFunctionKeyMask))
    {        
        switch (uc)
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
            str =  vt100flags.DECKPAM ?  ESC "OA" : ESC "[A";
            break;
        case NSDownArrowFunctionKey:
            str =  vt100flags.DECKPAM ?  ESC "OB" : ESC "[B";
            break;
        case NSRightArrowFunctionKey:
            str =  vt100flags.DECKPAM ?  ESC "OC" : ESC "[C";
            break;            
        case NSLeftArrowFunctionKey:
            str =  vt100flags.DECKPAM ?  ESC "OD" : ESC "[D";
            break;
            
        case NSF1FunctionKey:
            str = ESC "OP";
            break;
        case NSF2FunctionKey:
            str = ESC "OQ";
            break;
        case NSF3FunctionKey:
            str = ESC "OR";
            break;
        case NSF4FunctionKey:
            str = ESC "OS";
            break;   
            

        case '\n':
            if (vt100flags.LNM)
                output->write("\r\n");
            else output->write('\n');
            break;            
            
        case NSDeleteCharacter:
            uc = 0x7f;
            // fallthrough.
            
        default:
            
            if (uc <= 0x7f)
            {
                uint8_t c = uc;
                if (flags & NSControlKeyMask)
                {
                    c = CTRL(c);
                }
                output->write(c);
            }
            break;
    }
    
    if (str)
    {
        output->write(str);
    } 
    
    
}


static void vt52ModeKey(unichar uc, unsigned flags, Screen * screen, OutputChannel *output, struct __vt100flags vt100flags)
{
    const char *str = NULL;
    
    if (vt100flags.DECKPAM && (flags & NSNumericPadKeyMask))
    {
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
            str = ESC "A";
            break;
        case NSDownArrowFunctionKey:
            str = ESC "B";
            break;
        case NSRightArrowFunctionKey:
            str = ESC "C";
            break;            
        case NSLeftArrowFunctionKey:
            str = ESC "D";
            break;
            
        case NSF1FunctionKey:
            str = ESC "P";
            break;
        case NSF2FunctionKey:
            str = ESC "Q";
            break;
        case NSF3FunctionKey:
            str = ESC "R";
            break;
        case NSF4FunctionKey:
            str = ESC "S";
            break;   
        

            
        case NSDeleteCharacter:
            uc = 0x7f;
            // fallthrough..
            
        default:
        
            if (uc <= 0x7f)
            {
                uint8_t c = uc;
                if (flags & NSControlKeyMask)
                {
                    c = CTRL(c);
                }
                output->write(c);
            }
            break;
    }
    if (str)
    {
        output->write(str);
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
            vt52ModeKey(uc, flags, screen, output, _flags);
        else
            vt100ModeKey(uc, flags, screen, output, _flags);

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
        screen->tabTo(x + 1);
    }
    else
    {
        screen->tabTo((x + 8) & ~7);
    }
}


@end
