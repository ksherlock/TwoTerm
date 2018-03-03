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
#include <numeric>

#import "VT52.h"
#include "OutputChannel.h"
#include "Screen.h"

enum {
    StateText,
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
    ModelVT50,
    ModelVT50H,
    ModelVT52,
    ModelVT55
};



#if 0
@implementation VT50

+(void)load {
    [EmulatorManager registerClass: self];
}

+(NSString *)name {
    return @"VT50";
}
-(NSString *)name {
    return @"VT50";
}

-(const char *)termName {
    return "vt50";
}

-(struct winsize)displaySize
{
    struct winsize ws = { 24, 80, 0, 0 };
    
    return ws;
}


-(id)init {
    if ((self = [super init])) {
        _model = ModelVT50;
        [self reset: YES];

    }
    return self;
}

@end


@implementation VT50H

+(void)load {
    [EmulatorManager registerClass: self];
}


+(NSString *)name {
    return @"VT50H";
}

-(NSString *)name {
    return @"VT50H";
}

-(const char *)termName {
    return "vt50h";
}


-(id)init {
    if ((self = [super init])) {
        _model = ModelVT50H;
        [self reset: YES];

    }
    return self;
}

-(struct winsize)displaySize
{
    struct winsize ws = { 24, 80, 0, 0 };
    
    return ws;
}

@end

#endif

@implementation VT52

+(void)load {
    [EmulatorManager registerClass: self];
}


+(NSString *)name {
    return @"VT52";
}

-(NSString *)name {
    return @"VT52";
}

-(const char *)termName {
    return "vt52";
}

-(id)init {
    if ((self = [super init])) {
        _model = ModelVT52;
        [self reset: YES];
    }
    return self;
}
@end

@implementation VT55

+(void)load {
    //[EmulatorManager registerClass: self];
}

+(NSString *)name {
    return @"VT55";
}

-(NSString *)name {
    return @"VT55";
}

-(const char *)termName {
    return "vt55";
}

-(id)init {
    if ((self = [super init])) {
        _model = ModelVT55;
        [self reset: YES];

    }
    return self;
}
@end




#define ESC "\x1b"

@implementation VT5x




+(NSString *)name {
    return @"";
}

-(NSString *)name {
    return @"";
}

-(const char *)termName {
    return "";
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

-(void)reset: (BOOL)hard
{
    cs = StateText;
    _escape = false;
    _altKeyPad = false;
    _graphics = false;
    
    if (hard) {
        _context.cursor = iPoint(0,0);
        _context.window = iRect(0, 0, 80, 24);
        if (_model <= ModelVT50H) _context.window = iRect(0, 0, 80, 12);
    }
    _context.flags = 0;
}



static void advance(context &ctx, Screen *screen) {
    if (ctx.cursor.x < ctx.window.maxX()-1) ctx.cursor.x++;
}

-(void)processData: (uint8_t *)data length: (size_t)length screen: (Screen *)screen output: (OutputChannel *)output
{
    
    
    cs = std::accumulate(data, data + length, cs, [&](unsigned state, uint8_t c) -> unsigned {

        auto &cursor = _context.cursor;
        auto &window = _context.window;

        c &= 0x7f;
        if (c == 0x7f) return state; // pad character
        if (c < 32) {
            // control characters are always control characters
            switch(c) {
                // bell
                case 007: NSBeep(); break;
                // backspace
                case 010: if (cursor.x) cursor.x--; break;
                //tab
                case 011:
                    if (cursor.x < 72) cursor.x = (cursor.x + 8) & ~7;
                    else if (cursor.x < window.maxX() -1) cursor.x++;
                    break;
                // linefeed
                case 012:
                    if (cursor.y < window.maxY() -1) cursor.y++;
                    else {
                        if (_model <= ModelVT50H) screen->scrollUp();
                        screen->scrollUp();
                    }
                    break;
                // cr
                case 015: cursor.x = 0; break;
                // vt05-compatible dca
                case 016: 
                    if (_model == ModelVT50) return StateDCAY;
                    break;

                case 0x1b: // escape.
                    if (_model >= ModelVT52) _escape = true;
                    else _escape = !_escape;
                    break;
                
            }            
            return state;
        }

        if (state == StateDCAY) {
            c -= 32;
            //if (_model <= ModelVT50H) c *= 2; // double it up.

            if (c >= window.maxY()) {
                if (_model <= ModelVT50H) cursor.y = window.maxY() -1;
                else c = cursor.y;
            }
            cursor.y = c;
            return StateDCAX;
        }
        if (state == StateDCAX) {
            c -= 32;
            if (c >= window.maxX()) c = window.maxX() -1;
            cursor.x = c;
            return StateText;
        }
        
        if (_escape) {
            _escape = false;
            switch(c) {
                case 'A': if (cursor.y) cursor.y--; break;
                case 'B':
                    if (_model >= ModelVT50H && cursor.y < window.maxY() -1)
                        cursor.y++;
                    break;
                case 'C':
                    if (cursor.x < window.maxX() -1) cursor.x++;
                    break;
                case 'D':
                    if (_model >= ModelVT50H && cursor.x) cursor.x--;
                    break;

                // alt graphics
                case 'F':
                    if (_model >= ModelVT52) _graphics = true;
                    break;
                case 'G':
                    if (_model >= ModelVT52) _graphics = false;
                    break;


                // cursor home
                case 'H': cursor = iPoint(0,0); break;

                // reverse line feed
                case 'I':
                    // this is documented as being vt52++
                    // however the 2BSD termcap entry (dating to 1980)
                    // and every termcap since claims 50h supports it...
                    if (_model >= ModelVT50H) {
                        if (cursor.y) cursor.y--;
                        else {
                            screen->scrollDown();
                            if (_model <= ModelVT50H) screen->scrollDown();
                        }
                    }
                    break;

                case 'J': { 
                    // erase to end-of screen

                    iRect tmp;

                    if (_model <= ModelVT50H) {
                        cursor.y *= 2;
                        window.size.height *= 2;
                    }
                    
                    tmp.origin = cursor;
                    tmp.size = iSize( window.maxX() - cursor.x, 1);
                    screen->eraseRect(tmp);
                    
                    tmp.origin = iPoint(0, cursor.y+1);
                    tmp.size = iSize(window.maxX(), window.maxY() - cursor.y - 1);
                    screen->eraseRect(tmp);

                    if (_model <= ModelVT50H) {
                        cursor.y /= 2;
                        window.size.height /= 2;
                    }
                    
                    
                    break;
                }

                // erase to eol
                case 'K': {
                    iRect tmp;

                    if (_model <= ModelVT50H) {
                        cursor.y *= 2;
                        window.size.height *= 2;
                    }
                    
                    tmp.origin = cursor;
                    tmp.size = iSize( window.maxX() - cursor.x, 1);
                    screen->eraseRect(tmp);

                    if (_model <= ModelVT50H) {
                        cursor.y /= 2;
                        window.size.height /= 2;
                    }
                    
                    break;
                }



                // direct cursor addressing
                case 'Y':
                    if (_model >= ModelVT50H) {
                        _escape = false;
                        return StateDCAY;
                    }
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
                            output->write(ESC "/C");
                            break;
                    }
                    break;
                // alternate keypad
                case '=':
                    if (_model >= ModelVT52) _altKeyPad = true;
                    break;
                case '>':
                    if (_model >= ModelVT52) _altKeyPad = false;
                    break;

                    
            }
            return state;
        }
        // normal text!

        
        if (c >= 0140 && (_model <= ModelVT50H))
            c -= 040;

        if (_model <= ModelVT50H) {
            auto tmp = cursor; tmp.y *= 2;
            screen->putc(c, tmp, _context.flags);
        } else screen->putc(c, cursor, _context.flags);
        
        advance(_context, screen);
        return state;
        
        
    });

    if (_model <= ModelVT50H) {
        auto tmp = _context.cursor; tmp.y *= 2;
        screen->setCursor(tmp);
    } else screen->setCursor(_context.cursor);
  
}

-(BOOL)resizable
{
    return NO;

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
