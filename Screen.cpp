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
    
    _port.frame = iRect(0, 0, width, height);
    _port.rightMargin = TextPort::RMTruncate;
    _port.advanceCursor = true;
    _port.scroll = true;

    
    _flag = 0;
    
    _screen.resize(height);
    
    
    for (ScreenIterator iter = _screen.begin(); iter != _screen.end(); ++iter)
    {
        iter->resize(width);
    }
    
    
}

Screen::~Screen()
{
}


void Screen::beginUpdate()
{
    _lock.lock();
    _updates.clear();
    _updateCursor = _cursor;
}

iRect Screen::endUpdate()
{
    int maxX = -1;
    int maxY = -1;
    int minX = width();
    int minY = height();
    
    
    if (_cursor != _updateCursor)
    {
        _updates.push_back(_cursor);
        _updates.push_back(_updateCursor);
    }

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

void Screen::setFlagBit(uint8_t bit)
{
    _flag |= bit;
}
void Screen::clearFlagBit(uint8_t bit)
{
    _flag &= ~bit;
}


void Screen::putc(uint8_t c, bool incrementX)
{
    if (_cursor.x < width())
    {
        _updates.push_back(_cursor);

        _screen[_cursor.y][_cursor.x] = CharInfo(c, _flag);
        
        if (incrementX && _cursor.x < width() - 1) ++_cursor.x;
    }    
}

void Screen::deletec()
{
    // delete character at cursor.
    // move following character up
    // set final character to ' ' (retaining flags from previous char)
    
    if (_cursor.x >= width()) return;
    
    _updates.push_back(_cursor);
    _updates.push_back(iPoint(width() - 1, _cursor.y));
    
    
    CharInfoIterator end = _screen[_cursor.y].end() - 1;
    CharInfoIterator iter = _screen[_cursor.y].begin() + _cursor.x;
    

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
    
    if (_cursor.x >= width()) return;
    
    _updates.push_back(_cursor);
    _updates.push_back(iPoint(width() - 1, _cursor.y));
    
    CharInfoIterator end = _screen[_cursor.y].end() - 1;
    CharInfoIterator iter = _screen[_cursor.y].begin() + _cursor.x;
    
    for ( ; iter != end; ++iter)
    {
        iter[1] = iter[0];
    }
    
    iter->c = ' ';
}


void Screen::tabTo(unsigned xPos)
{
    CharInfo clear(' ', _flag);
    CharInfoIterator iter;
    
    xPos = std::min((int)xPos, width() - 1);
    
    
    _updates.push_back(_cursor);
    _updates.push_back(iPoint(xPos, _cursor.y));
                       
    for (unsigned x = _cursor.x; x < xPos; ++x)
    {
        _screen[_cursor.y][x] = clear;
    }
    _cursor.x = xPos;
}


void Screen::setX(int x, bool clamp)
{
    if (x < 0)
    {
        if (clamp) _cursor.x = 0;
        return;
    }
    if (x >= width())
    {
        if (clamp) _cursor.x = width() - 1;
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
    if (y >= height())
    {
        if (clamp) _cursor.y = height() - 1;
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




void Screen::erase(EraseRegion region)
{

    CharInfoIterator ciIter;
    ScreenIterator screenIter;
    
    if (region == EraseAll)
    {
        ScreenIterator end = _screen.end();
        for (screenIter = _screen.begin(); screenIter < end; ++screenIter)
        {
            std::fill(screenIter->begin(), screenIter->end(), CharInfo(0,0));
        }
        _updates.push_back(iPoint(0,0));
        _updates.push_back(iPoint(width() - 1, height() - 1));
        
        return;
    }
    
    
    // TODO -- be smart and check if cursor is at x = 0 (or x = _width - 1)
    if (region == EraseBeforeCursor)
    {
        ScreenIterator end = _screen.begin() + _cursor.y - 1;
        for (screenIter = _screen.begin(); screenIter < end; ++screenIter)
        {
            std::fill(screenIter->begin(), screenIter->end(), CharInfo(0,0));
        }
        _updates.push_back(iPoint(0,0));
        _updates.push_back(iPoint(width() - 1, _cursor.y));
        
        region = EraseLineBeforeCursor;
    }
    
    if (region == EraseAfterCursor)
    {
        ScreenIterator end = _screen.end();
        for (screenIter = _screen.begin() + _cursor.y + 1; screenIter < end; ++screenIter)
        {
            std::fill(screenIter->begin(), screenIter->end(), CharInfo(0,0));
        }
        _updates.push_back(iPoint(0,_cursor.y + 1));
        _updates.push_back(iPoint(width() - 1, height() - 1));
        
        region = EraseLineAfterCursor;
    }
    
    if (region == EraseLineAll)
    {
    
        int y = _cursor.y;
        std::fill(_screen[y].begin(), _screen[y].end(), CharInfo(0,0));
        
        _updates.push_back(iPoint(0, _cursor.y));
        _updates.push_back(iPoint(width() - 1, _cursor.y));
        
        return;
    }
    
    if (region == EraseLineBeforeCursor)
    {
        int y = _cursor.y;
        std::fill(_screen[y].begin(), _screen[y].begin() + _cursor.x + 1, CharInfo(0,0));
        
        _updates.push_back(iPoint(0, _cursor.y));
        _updates.push_back(_cursor);
        
        return;        
    }
    
    if (region == EraseLineAfterCursor)
    {
        int y = _cursor.y;
        std::fill(_screen[y].begin() + _cursor.x, _screen[y].end(), CharInfo(0,0));
        
        _updates.push_back(_cursor);     
        _updates.push_back(iPoint(width() - 1, _cursor.y));
        
    }
    
    
}

void Screen::eraseLine()
{
    // erases everything to the right of, and including, the cursor
    
    for (CharInfoIterator ciIter = _screen[_cursor.y].begin() + _cursor.x; ciIter < _screen[_cursor.y].end(); ++ciIter)
    {
        *ciIter = CharInfo(0, _flag);
    }
    
    _updates.push_back(_cursor);
    _updates.push_back(iPoint(width() - 1, _cursor.y));
}
void Screen::eraseScreen()
{
    // returns everything to the right of, and including, the cursor as well as all subsequent lines.
    
    eraseLine();
    
    if (_cursor.y == height() -1) return;
    
    for (ScreenIterator iter = _screen.begin() + _cursor.y; iter < _screen.end(); ++iter)
    {
        for (CharInfoIterator ciIter = iter->begin(); ciIter < iter->end(); ++ciIter)
        {
            *ciIter = CharInfo(0, _flag);
        }
        
    }
    
    _updates.push_back(iPoint(0, _cursor.y + 1));
    _updates.push_back(iPoint(width() - 1, height() - 1));
}


void Screen::eraseRect(iRect rect)
{

    unsigned maxX = std::min(width(), rect.maxX());
    unsigned maxY = std::min(height(), rect.maxY());
    
    CharInfo clear;
    
    for (unsigned y = rect.minY(); y < maxY; ++y)
    {
        for (unsigned x = rect.minX(); x < maxX; ++x)
        {
            _screen[y][x] = clear;
        }
    }
    
    _updates.push_back(rect.origin);
    _updates.push_back(iPoint(maxX - 1, maxY - 1));
}



void Screen::lineFeed()
{
    // moves the screen up one row, inserting a blank line at the bottom.

    if (_cursor.y == height() - 1)
    {        
        deleteLine(0);
    }
    else
    {
        _cursor.y++;
    }
}

void Screen::lineFeed(TextPort *textPort)
{
    int maxY;
    
    if (!textPort)
    {
        lineFeed();
        return;
    }
    
    maxY = textPort->frame.maxY();
    
    maxY = std::min(maxY, (int)height());
    
    if (_cursor.y < maxY)
    {
        _cursor.y++;
    }
    else if (textPort->scroll)
    {
        _cursor.y++;
    }
    
}


void Screen::reverseLineFeed()
{  
    // moves the cursor down one row, inserting a blank line at the top.
    
    if (_cursor.y == 0)
    {
        insertLine(0);
    }
    else
    {
        _cursor.y--;
    }
    
}


void Screen::insertLine(unsigned line)
{

    if (line >= height()) return;
    
    if (line == height() - 1)
    {
        _screen.back().clear();
        _screen.back().resize(width());
    }
    else
    {
        std::vector<CharInfo> newLine;
        ScreenIterator iter;
        
        _screen.pop_back();
        iter = _screen.insert(_screen.begin() + line, newLine);
        iter->resize(width());
    }

    _updates.push_back(iPoint(0, line));
    _updates.push_back(iPoint(width() - 1, height() - 1));
}

// line is relative to the textView.
// textView has been constrained.

void Screen::insertLine(TextPort *textPort, unsigned line)
{
    iRect frame;
    CharInfo ci;
    
    int minY;
    int maxY;
    int minX;
    int maxX;
    
    if (!textPort) return insertLine(line);
    
    frame = textPort->frame;
    
    minY = frame.minY();
    maxY = frame.maxY();
    
    minX = frame.minX();
    minY = frame.maxX();
    
    if (line < 0) return;
    if (line >= frame.height()) return;
        
    // move all subsequent lines forward by 1.
    for (int y = maxY - 2; y >= minY + line; --y)
    {
        CharInfoIterator iter;
        CharInfoIterator end;
        
        iter = _screen[y].begin() + minX;
        end = _screen[y].begin() + maxX;
        
        std::copy(iter, end, _screen[y + 1].begin() + minX);
    }
    
    // clear the line.
    std::fill(_screen[minY + line].begin() + minX, _screen[minY + line].begin() + maxX, ci);
    
    // set the update region.
    
    _updates.push_back(iPoint(minX, minY + line));
    _updates.push_back(iPoint(maxX - 1, maxY - 1));

}

void Screen::deleteLine(unsigned line)
{

    if (line >= height()) return;
    
    if (line == height() - 1)
    {
        _screen.back().clear();

    }
    else
    {
        std::vector<CharInfo> newLine;
        
        _screen.erase(_screen.begin() + line);

        _screen.push_back(newLine);
    }
    
    _screen.back().resize(width());
    
    
    _updates.push_back(iPoint(0, line));
    _updates.push_back(iPoint(width() - 1, height() - 1));    
}


void Screen::deleteLine(TextPort *textPort, unsigned line)
{
    iRect frame;
    CharInfo ci;
    
    int minY;
    int maxY;
    int minX;
    int maxX;
    
    if (!textPort) return deleteLine(line);
    
    frame = textPort->frame;
    
    minY = frame.minY();
    maxY = frame.maxY();
    
    minX = frame.minX();
    minY = frame.maxX();
    
    if (line < 0) return;
    if (line >= frame.height()) return;
    
    // move all subsequent lines back by 1.
    for (int y = minY + line; y < maxY - 2; ++y)
    {
        CharInfoIterator iter;
        CharInfoIterator end;
        
        iter = _screen[y + 1].begin() + minX;
        end = _screen[y + 1].begin() + maxX;
        
        std::copy(iter, end, _screen[y].begin() + minX);
    }
    
    // clear the last line.
    std::fill(_screen[maxY - 1].begin() + minX, _screen[maxY - 1].begin() + maxX, ci);
    
    // set the update region.
    
    _updates.push_back(iPoint(minX, minY + line));
    _updates.push_back(iPoint(maxX - 1, maxY - 1));
    
}



void Screen::setSize(unsigned w, unsigned h)
{

    if ((height() == h) && (width() == w)) return;
    
    if (height() < h)
    {
        _screen.resize(h);        
    }
    else if (height() > h)
    {
        unsigned count = height() - h;
        // erase lines from the top.
        _screen.erase(_screen.begin(), _screen.begin() + count);
    }

    
    //if (_width != _width || _height != height)
    {
        ScreenIterator iter;
        for (iter = _screen.begin(); iter != _screen.end(); ++iter)
        {
            iter->resize(w);
        }

    }

    _port.frame.size = iSize(w, h);


    if (_cursor.y >= h) _cursor.y = h - 1;
    if (_cursor.x >= w) _cursor.x = w - 1;
    
    //fprintf(stderr, "setSize(%u, %u)\n", width, height);
        
}