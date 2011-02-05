//
//  Screen_obsolete.cpp
//  2Term
//
//  Created by Kelvin Sherlock on 1/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "Screen.h"

void Screen::setX(int x, bool clamp)
{
    if (x < 0)
    {
        if (clamp) _port.cursor.x = 0;
        return;
    }
    if (x >= width())
    {
        if (clamp) _port.cursor.x = width() - 1;
        return;
    }
    
    _port.cursor.x = x;
}


void Screen::setY(int y, bool clamp)
{
    if (y < 0)
    {
        if (clamp) _port.cursor.y = 0;
        return;
    }
    if (y >= height())
    {
        if (clamp) _port.cursor.y = height() - 1;
        return;
    }
    
    _port.cursor.y = y;
}

int Screen::incrementX(bool clamp)
{
    setX(_port.cursor.x + 1, clamp);
    return _port.cursor.x;
}

int Screen::decrementX(bool clamp)
{
    setX(_port.cursor.x - 1, clamp);
    return _port.cursor.x;
}

int Screen::incrementY(bool clamp)
{
    setY(_port.cursor.y + 1, clamp);
    return _port.cursor.y;
}

int Screen::decrementY(bool clamp)
{
    setY(_port.cursor.y - 1, clamp);
    return _port.cursor.y;
}

void Screen::tabTo(unsigned xPos)
{
    CharInfo clear(' ', _flag);
    CharInfoIterator iter;
    
    xPos = std::min((int)xPos, width() - 1);
    
    
    _updates.push_back(_port.cursor);
    _updates.push_back(iPoint(xPos, _port.cursor.y));
    
    for (unsigned x = _port.cursor.x; x < xPos; ++x)
    {
        _screen[_port.cursor.y][x] = clear;
    }
    _port.cursor.x = xPos;
}




void Screen::putc(uint8_t c, bool incrementX)
{
    if (_port.cursor.x < width())
    {
        _updates.push_back(_port.cursor);
        
        _screen[_port.cursor.y][_port.cursor.x] = CharInfo(c, _flag);
        
        if (incrementX && _port.cursor.x < width() - 1) ++_port.cursor.x;
    }    
}



void Screen::deletec()
{
    // delete character at cursor.
    // move following character up
    // set final character to ' ' (retaining flags from previous char)
    
    if (_port.cursor.x >= width()) return;
    
    _updates.push_back(_port.cursor);
    _updates.push_back(iPoint(width() - 1, _port.cursor.y));
    
    
    CharInfoIterator end = _screen[_port.cursor.y].end() - 1;
    CharInfoIterator iter = _screen[_port.cursor.y].begin() + _port.cursor.x;
    
    
    for ( ; iter != end; ++iter)
    {
        iter[0] = iter[1];
        
    }
    // retain the flags previously there.
    end->c = ' ';
}


void Screen::insertc(uint8_t c)
{
    // insert character at cursor.
    // move following characters up (retaining flags).
    
    if (_port.cursor.x >= width()) return;
    
    _updates.push_back(_port.cursor);
    _updates.push_back(iPoint(width() - 1, _port.cursor.y));
    
    CharInfoIterator end = _screen[_port.cursor.y].end() - 1;
    CharInfoIterator iter = _screen[_port.cursor.y].begin() + _port.cursor.x;
    
    for ( ; iter != end; ++iter)
    {
        iter[1] = iter[0];
    }
    
    iter->c = ' ';
}

void Screen::eraseLine()
{
    // erases everything to the right of, and including, the cursor
    
    for (CharInfoIterator ciIter = _screen[y()].begin() + x(); ciIter < _screen[y()].end(); ++ciIter)
    {
        *ciIter = CharInfo(0, _flag);
    }
    
    _updates.push_back(cursor());
    _updates.push_back(iPoint(width() - 1, y()));
}

void Screen::eraseScreen()
{
    // returns everything to the right of, and including, the cursor as well as all subsequent lines.
    
    eraseLine();
    
    if (y() == height() -1) return;
    
    for (ScreenIterator iter = _screen.begin() + y(); iter < _screen.end(); ++iter)
    {
        for (CharInfoIterator ciIter = iter->begin(); ciIter < iter->end(); ++ciIter)
        {
            *ciIter = CharInfo(0, _flag);
        }
        
    }
    
    _updates.push_back(iPoint(0, y() + 1));
    _updates.push_back(iPoint(width() - 1, height() - 1));
}

