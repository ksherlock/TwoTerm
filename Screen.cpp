/*
 *  Screen.cpp
 *  2Term
 *
 *  Created by Kelvin Sherlock on 7/7/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "Screen.h"

#include <algorithm>

Screen::Screen(unsigned height, unsigned width)
{
    _height = height;
    _width = width;
    
    _flag = 0;
    
    _screen.resize(_height);
    
    
    for (ScreenIterator iter = _screen.begin(); iter != _screen.end(); ++iter)
    {
        iter->resize(_width);
    }
    
    
}


void Screen::beginUpdate()
{
    _lock.lock();
    _updates.clear();
}

iRect Screen::endUpdate()
{
    int maxX = -1;
    int maxY = -1;
    int minX = _width;
    int minY = _height;
    
    

    for (UpdateIterator iter = _updates.begin(); iter != _updates.end(); ++iter)
    {
        maxX = std::max(maxX, iter->x);
        maxY = std::max(maxY, iter->y);
        
        minX = std::min(minX, iter->x);
        minY = std::min(minY, iter->y);
    }
    
    _lock.unlock();
    
    return iRect(iPoint(minX, minY), iSize(maxX + 1 - minX, maxY + 1 - minY)); 
}

void Screen::setFlag(uint8_t flag)
{
    _flag = flag;
}


void Screen::putc(uint8_t c, bool incrementX)
{
    if (_cursor.x < _width)
    {
        _updates.push_back(_cursor);

        _screen[_cursor.y][_cursor.x] = CharInfo(c, _flag);
        
        if (incrementX && _cursor.x < _width - 1) ++_cursor.x;
    }    
}

void Screen::setX(int x, bool clamp)
{
    if (x < 0)
    {
        if (clamp) _cursor.x = 0;
        return;
    }
    if (x >= _width)
    {
        if (clamp) _cursor.x = _width - 1;
        return;
    }
    
    _cursor.x = x;
}


void Screen::setY(int y, bool clamp)
{
    if (y < 0)
    {
        if (clamp) _cursor.y = 0;
        return;
    }
    if (y >= _height)
    {
        if (clamp) _cursor.y = _height - 1;
        return;
    }
    
    _cursor.y = y;
}



int Screen::incrementX(bool clamp)
{
    setX(_cursor.x + 1, clamp);
    return _cursor.x;
}

int Screen::decrementX(bool clamp)
{
    setX(_cursor.x - 1, clamp);
    return _cursor.x;
}

int Screen::incrementY(bool clamp)
{
    setY(_cursor.y + 1, clamp);
    return _cursor.y;
}

int Screen::decrementY(bool clamp)
{
    setY(_cursor.y - 1, clamp);
    return _cursor.y;
}


void Screen::eraseLine()
{
    // erases everything to the right of, and including, the cursor
    
    for (CharInfoIterator ciIter = _screen[_cursor.y].begin() + _cursor.x; ciIter < _screen[_cursor.y].end(); ++ciIter)
    {
        *ciIter = CharInfo(0, _flag);
    }
    
    _updates.push_back(_cursor);
    _updates.push_back(iPoint(_width - 1, _cursor.y));
}
void Screen::eraseScreen()
{
    // returns everything to the right of, and including, the cursor as well as all subsequent lines.
    
    eraseLine();
    
    if (_cursor.y == _height -1) return;
    
    for (ScreenIterator iter = _screen.begin() + _cursor.y; iter < _screen.end(); ++iter)
    {
        for (CharInfoIterator ciIter = iter->begin(); ciIter < iter->end(); ++ciIter)
        {
            *ciIter = CharInfo(0, _flag);
        }
        
    }
    
    _updates.push_back(iPoint(0, _cursor.y + 1));
    _updates.push_back(iPoint(_width - 1, _height - 1));
}


void Screen::lineFeed()
{
    // moves the screen up one row, inserting a blank line at the bottom.

    if (_cursor.y == _height - 1)
    {
        
        // move lines 1..end up 1 line.
        for (ScreenIterator iter = _screen.begin() + 1; iter < _screen.end(); ++iter)
        {
            iter[-1] = *iter;
        }
        
        // reset the bottom line
        //_screen.back().clear();
        //_screen.back().resize(_width);
        
        for (CharInfoIterator ciIter = _screen.back().begin(); ciIter < _screen.back().end(); ++ciIter)
        {
            *ciIter = CharInfo(0, 0);
        }        

        _updates.push_back(iPoint(0, 0));
        _updates.push_back(iPoint(_width - 1, _height - 1));
    }
    else
    {
        _cursor.y++;
    }
}

void Screen::reverseLineFeed()
{  
    // moves the cursor down one row, inserting a blank line at the top.
    
    if (_cursor.y == 0)
    {

        for (ReverseScreenIterator iter = _screen.rbegin() + 1; iter < _screen.rend(); ++iter)
        {
            iter[-1] = *iter;
        }        
        
        // reset the top line
        //_screen.front().clear();
        //_screen.front().resize(_width);
        
        for (CharInfoIterator ciIter = _screen.front().begin(); ciIter < _screen.front().end(); ++ciIter)
        {
            *ciIter = CharInfo(0, 0);
        }
        
        _updates.push_back(iPoint(0, 0));
        _updates.push_back(iPoint(_width - 1, _height - 1));
    }
    else
    {
        _cursor.y--;
    }

}