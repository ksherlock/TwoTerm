//
//  VT52View.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <cctype>
#include <algorithm>

#import "VT52View.h"

const char esc = 0x1b;
#define ESC "\x1b"

enum {
    StateText,
    StateEscape,
    StateEscapeY1,
    StateEscapeY2
};


@interface VT52View (Cursor)

-(void)cursorLeft;
-(void)cursorRight;
-(void)cursorUp;
-(void)cursorDown;
-(void)cursorHome;

-(void)_setCursor: (CursorPosition)cursor;

-(void)lineFeed;
-(void)reverseLineFeed;
-(void)carriageReturn;

-(void)tab;

@end

@interface VT52View (Private)


-(void)invalidate;


-(void)processCharacter: (uint8_t)c;

-(void)appendChar: (uint8_t)c;

-(void)eraseLine;
-(void)eraseScreen;

@end



@implementation VT52View





-(void)dataAvailable
{
    //NB -- this is not the main thread.

    
    // actually read the data
    for(;;)
    {
        ssize_t i;
        uint8_t buffer[512];
        ssize_t size = read(_fd, buffer, sizeof(buffer));
        NSAutoreleasePool *pool;
        
        if (size == 0) break;
        if (size < 0)
        {
            if (errno == EAGAIN) break;
            
            perror("[VT52View dataAvailable] : read: ");
            break;
        }
  
        [_lock lock];
        
        pool = [NSAutoreleasePool new];
        for (i = 0 ; i < size; ++i)
        {
            //if (buffer[i] < ' ') std::fprintf(stderr, "%02x\n", (int)buffer[i]);
            [self processCharacter: buffer[i]];
        }
        [self invalidate];
        
        [_lock unlock];
        [pool release];
    }
    
}


-(void)keyDown: (NSEvent *)theEvent
{
    unsigned flags = [theEvent modifierFlags];
    NSString *chars = [theEvent charactersIgnoringModifiers];
    
    unsigned length = [chars length];
    unsigned i;
    
    if (flags & NSCommandKeyMask) return;
    
    // length should always be 1...
    for (i = 0 ; i < length; ++i)
    {
        unichar uc = [chars characterAtIndex: i];
        char c;
        

        if (flags & NSNumericPadKeyMask)
        {
            const char *str = NULL;
            if (_altKeyPad)
            {
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
                    case NSNewlineCharacter:
                    case NSEnterCharacter:
                        str = ESC "?M";
                        break;
                        
                }
            }
            
            switch (uc)
            {
                case NSEnterCharacter:
                    uc = '\r';
                    break;
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
            }
            if (str)
            {
                ssize_t size = write(_fd, str, strlen(str));
                if (size < 0)
                {
                    perror("keyDown: write");
                }
                continue;
            }
            
        }
        
        if (uc > 0x7f) continue;
        c = uc;
        
        if (flags & NSControlKeyMask)
        {
            // 040, 0100, and 0140 are all equivalent
            c &= 0x1f;
        }
        /*
        else
        {
            if (c == NSEnterCharacter) c = '\r';
        }
        */

        
        write(_fd, &c, 1); 
    }
}




@end




@implementation VT52View (Cursor)

// these are not thread safe...

#pragma mark -
#pragma mark Cursor Control
-(void)setCursor: (CursorPosition)cursor
{
    [_lock lock];
    [self _setCursor: cursor];
    //[self invalidate];
    [_lock unlock];
}

-(void)_setCursor: (CursorPosition)cursor
{
    
    if (cursor.x < 0) cursor.x = 0;
    if (cursor.x >= _width) cursor.x = _width - 1;
    
    if (cursor.y < 0) cursor.y = 0;
    if (cursor.y >= _height) cursor.y = _height - 1;
    
    if (cursor == _cursor) return;
    
    // TODO -- cursor should be a child view, to handle blinking, cursor style, etc.
    //_updates.push_back(_cursor);
    //_updates.push_back(cursor);
    _cursor = cursor;    
}

-(void)cursorLeft
{
    if (_cursor.x == 0) return;
    
    [self _setCursor: CursorPosition(_cursor.x - 1, _cursor.y)];
}

-(void)cursorRight
{
    if (_cursor.x == (_width - 1)) return;
    
    [self _setCursor: CursorPosition(_cursor.x + 1, _cursor.y)];
}

-(void)cursorUp
{
    if (_cursor.y == 0) return;
    
    [self _setCursor: CursorPosition(_cursor.x, _cursor.y - 1)];
}

-(void)cursorDown
{
    if (_cursor.y == (_height - 1)) return;
    
    [self _setCursor: CursorPosition(_cursor.x, _cursor.y + 1)];
}

-(void)lineFeed
{
    // increment line, column doesn't change.  If already on the bottom line, a 1-line scroll occurs.
    
    if (_cursor.y == _height - 1)
    {
        CharInfo tmp = {0,0};
        // scroll all the lines....
        for (unsigned y = 1; y < _height; ++y)
        {
            for (unsigned x = 0; x < _width; ++x)
            {
                _screen[y-1][x] = _screen[y][x];
            }
        }
        
        for (unsigned x = 0; x < _width; ++x)
        {
            _screen[_height -1][x] = tmp;
        }
        
        
        [self setNeedsDisplay: YES];
    }
    else
    {
        [self _setCursor: CursorPosition(_cursor.x, _cursor.y + 1)];
    }
}

-(void)reverseLineFeed
{
    // decrement line, column doesn't change.  If already on the bottom line, a 1-line scroll occurs.
    
    if (_cursor.y == 0)
    {
        CharInfo tmp = {0,0};
        // scroll all the lines....
        for (unsigned y = 0; y < _height - 1; ++y)
        {
            for (unsigned x = 0; x < _width; ++x)
            {
                _screen[y+1][x] = _screen[y][x];
            }
        }
        
        for (unsigned x = 0; x < _width; ++x)
        {
            _screen[0][x] = tmp;
        }
        
        
        [self setNeedsDisplay: YES];
    }
    else
    {
        [self _setCursor: CursorPosition(_cursor.x, _cursor.y - 1)];
    }    
}


-(void)carriageReturn
{
    // move x to 0.
    if (_cursor.x == 0) return;
    [self _setCursor: CursorPosition(0, _cursor.y)];
}

-(void)cursorHome
{
    [self _setCursor: CursorPosition(0,0)];
}

-(void)tab
{
    // TODO -- does this insert spaces?
    
    // move right 1 (or more) positions.
    // stops (1-based): 9, 17, 25, 33, 41, 49, 57, 65, 73, 
    // if x >= 73, move right 1.  If x == _width
    
    int x = _cursor.x;
    
    if (x == _width -1) return;
    
    //x += 1;
    // doesn't handle end case...
    x = (x + 8) & ~0x07;
    
    [self _setCursor: CursorPosition(x, _cursor.y)];
}

@end



@implementation VT52View (Private)


-(void)invalidate
{
    // caller must lock prior to calling.
    // resets the _updates list.
    
    std::vector<struct CursorPosition>::iterator iter;
    
    int minX = _width - 1;
    int maxX = 0;
    int minY = _height - 1;
    int maxY = 0;
    
    if (_updates.empty()) return;
    
    
    for (iter = _updates.begin(); iter != _updates.end(); ++iter)
    {
        minX = std::min(minX, iter->x);
        maxX = std::max(maxX, iter->x);
        minY = std::min(minY, iter->y);
        maxY = std::max(maxY, iter->y);
    }
    
    // TODO -- character height/width sizes.
    
    
    
    [self setNeedsDisplayInRect: NSMakeRect(minX * _charWidth, minY * _charHeight, (maxX - minX + 1) * _charWidth, (maxY - minY + 1) * _charHeight)];
    
    
    _updates.clear();
    
}



// state machine.
-(void)processCharacter: (uint8_t)c
{
    
    switch (_state)
    {
        case StateText:
        {
            switch (c)
            {
                case 0x00:
                case 0x7f:
                    // padding;
                    break;
                    
                case 0x1b:
                    _state = StateEscape;
                    break;
                    
                case 0x07:
                    // bell...
                    NSBeep();
                    break;
                    
                case 0x08:
                    [self cursorLeft];
                    // backspace
                    break;
                    
                case 0x09:
                    // tab
                    [self tab];
                    break;
                    
                case 0x0a:
                case 0x0b:
                case 0x0c:
                    // lf
                    [self lineFeed];
                    break;
                    
                case 0x0d:
                    // cr
                    [self carriageReturn];
                    break;
                    
                case 0x0e:
                case 0x0f:
                    // g0/g1 char set
                    break;
                    
                default:
                    if (c >= 0x20 && c <= 0x7f)
                        [self appendChar: c];   
                    break;
                    
            }
            break;
        }
            
        case StateEscape:
        {
            switch (c)
            {
                case 0x00:
                case 0x7f:
                    break;
                case 0x1b:
                    // on vt52 is ignored, on vt50 cancels escape sequence.
                    if (_vt50) _state = StateText;
                    break;
                    
                    
                case 'A':
                    _state = StateText;
                    [self cursorUp];
                    break;
                case 'B':
                    _state = StateText;
                    [self cursorDown];
                    break;
                case 'C':
                    _state = StateText;
                    [self cursorRight];   
                    break;
                case 'D':
                    _state = StateText;
                    [self cursorLeft];
                    break;
                    
                case 'I':
                    _state = StateText;
                    if (!_vt50)
                        [self reverseLineFeed];
                    break;
                    
                case 'H':
                    _state = StateText;
                    [self _setCursor: CursorPosition(0,0)];
                    break;
                
                case 'J':
                    _state = StateText;
                    [self eraseScreen];
                    break;
                    
                case 'K':
                    _state = StateText;
                    [self eraseLine];
                    break;
                    
                case 'Y':
                    _state = StateEscapeY1;
                    break;
                    
                    
                case '=':
                    _state = StateText;
                    _altKeyPad = YES;
                    break;
                    
                case '>':
                    _state = StateText;
                    _altKeyPad = NO;
                    break;
                    
                case 'Z':
                    //identity
                    _state = StateText;
                    
                    write(_fd, _vt50 ? ESC "/A" : ESC "/K", 3);
                    break;
                    
                case '1':
                case '2':
                    // alt graphic modes (unsupported)
                    _state = StateText;
                    break;
                    
                case 'F':
                case 'G':
                    _state = StateText;
                    // graphic/ascii char set (unsupported)
                    break;
                    
                    /*
                     case '<':
                     //ANSI mode (vt100)
                     _state = StateText;
                     break;
                     */
                    
                    
                default:
                    _state = StateText;
                    std::fprintf(stderr, "Unrecognized escape character: %c\n", c);
                    break;
            }
            
            
            break;
        }
            
            /*
             * ESC Y line# column#
             * line# 040--067
             * 
             * vt50H moved to bottom line if out of bounds.
             * vt52 does not adjust if out of bounds.
             *
             * column# 040--0157
             * if out of bounds, moves to the rightmost column.
             */
            
        case StateEscapeY1:
        {
            _state = StateEscapeY2;
            if (c >= 0x20) c -= 0x20;
            else c = -1;
            
            _yTemp[0] = c;
            break;
        }
        case StateEscapeY2:
        {
            CursorPosition cp = _cursor;
            
            _state = StateText;
            
            if (c >= 0x20) c -= 0x20;
            else c = -1;
            
            _yTemp[1] = c;
            
            // vt52 style.
            if (_yTemp[0] < _height) cp.y = _yTemp[0];
            if (_yTemp[1] < _width) cp.x = _yTemp[1];
            
            [self _setCursor: cp];
            
            break;
        }
    }
}

-(void)appendChar: (uint8_t)c
{
    CharInfo ci = { c, 0 };
    int x = _cursor.x;
    int y = _cursor.y;
    
    if (y == _width) return; // eol.
    
    _screen[y][x] = ci;
    
    _updates.push_back(_cursor);
    
    [self _setCursor: CursorPosition(x + 1, y)];
}

-(void)eraseLine
{
    
    CharInfo clear = {0, 0};
    
    for (unsigned x = _cursor.x; x < _width; ++x)
    {
        _screen[_cursor.y][x] = clear;
    }
    // everything in between will be redrawn...
    _updates.push_back(_cursor);
    _updates.push_back(CursorPosition(_width - 1, _cursor.y));
}

-(void)eraseScreen
{
    CharInfo clear = {0, 0};
    
    // erase line and all lines below.
    [self eraseLine];
    
    for (unsigned y = _cursor.y + 1; y < _height; ++y)
    {
        for (unsigned x = 0; x < _width; ++x)
        {
            _screen[y][x] = clear;
        }
    }
    
    _updates.push_back(CursorPosition(0, _cursor.y + 1));
    _updates.push_back(CursorPosition(_width - 1, _height - 1));
    
}

@end