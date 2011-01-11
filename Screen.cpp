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

iPoint TextPort::absoluteCursor() const
{
    return iPoint(frame.origin.x + cursor.x, frame.origin.y + cursor.y);
}



Screen::Screen(unsigned height, unsigned width)
{
    
    _port.frame = iRect(0, 0, width, height);
    _port.rightMargin = TextPort::MarginTruncate;
    _port.rightMargin = TextPort::MarginTruncate;

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
    _updateCursor = cursor();
}

iRect Screen::endUpdate()
{
    int maxX = -1;
    int maxY = -1;
    int minX = width();
    int minY = height();
    
    iPoint c = cursor();
    
    if (c != _updateCursor)
    {
        _updates.push_back(c);
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





void Screen::putc(TextPort *textPort, uint8_t c)
{
    /*
     * textport must be valid.
     * cursor must be within textport.
     */
    

    if (!textPort) textPort = &_port;
    iPoint cursor = textPort->absoluteCursor();
    
    // right margin is a special case.
    if (textPort->cursor.x == textPort->frame.width() -1)
    {
        if (textPort->rightMargin == TextPort::MarginTruncate) return;
        if (textPort->rightMargin == TextPort::MarginOverwrite)
        {
            _updates.push_back(cursor);
            _screen[cursor.y][cursor.x] = CharInfo(c, _flag);
            return;
        }
        //if (textPort->rightMargin == TextPort::MarginWrap)
    }

    _updates.push_back(cursor);
    _screen[cursor.y][cursor.x] = CharInfo(c, _flag);
        
    if (textPort->advanceCursor)
    {
        incrementX(textPort);
    }

}



void Screen::tabTo(TextPort *textPort, unsigned xPos)
{
    if (!textPort) textPort = &_port;
 
    CharInfo clear(' ', _flag);
    iPoint cursor = textPort->absoluteCursor();
    
    xPos = std::min((int)xPos, textPort->frame.width() - 1);
    
    _updates.push_back(cursor);
    
    for (unsigned x = textPort->cursor.x; x < xPos; ++x)
    {
        
        _screen[cursor.y][x + textPort->frame.minX()] = clear;
    }
    
    textPort->cursor.x += xPos;
    if (textPort != &_port) _port.cursor = textPort->absoluteCursor();

    _updates.push_back(_port.cursor);

}


#pragma mark -
#pragma mark Cursor manipulation.




/*
 * sets cursor.x within the textport.
 * if x is outside the textport and clampX is true, it will be clamped to 0/width-1
 * if x is outside the textport and clampX is false, x will not be updated.
 *
 * returns the new cursor.x
 */

int Screen::setX(TextPort *textPort, int x)
{
    // honors clampX.
    if (!textPort) textPort = &_port;

    bool clamp = textPort->clampX;
    
    if (x < 0)
    {
        if (clamp) textPort->cursor.x = 0;
    }
    else if (x >= textPort->frame.width())
    {
        if (clamp) textPort->cursor.x = textPort->frame.width() - 1;
    }
    else
    {
        textPort->cursor.x = x;
    }

    if (textPort != &_port) _port.cursor = textPort->absoluteCursor();
    
    return textPort->cursor.x;
}

/*
 * sets cursor.y within the textport.
 * if y is outside the textport and clampY is true, it will be clamped to 0/height-1
 * if y is outside the textport and clampY is false, y will not be updated.
 *
 * returns the new cursor.y
 */

int Screen::setY(TextPort *textPort, int y)
{
    // honors clampY.
    
    if (!textPort) textPort = &_port;
    
    bool clamp = textPort->clampY;
    
    if (y < 0)
    {
        if (clamp) textPort->cursor.y = 0;
    }
    else if (y >= textPort->frame.height())
    {
        if (clamp) textPort->cursor.y = textPort->frame.height() - 1;
    }
    else
    {
        textPort->cursor.y = y;
    }
    
    if (textPort != &_port) _port.cursor = textPort->absoluteCursor();
    
    return textPort->cursor.y;    
}

/*
 * increments cursor.x within the textport.
 * if rightMargin wraps, it will set x = 0 and incrementY (which may scroll)
 * if rightMargin does not wrap, it will not be updated.
 *
 * returns the new cursor.x
 */
int Screen::incrementX(TextPort *textPort)
{
    // honors wrap, scroll.
    if (!textPort) textPort = &_port;
    

    if (textPort->cursor.x == textPort->frame.width() - 1)
    {
        if (textPort->rightMargin == TextPort::MarginWrap)
        {
            textPort->cursor.x = 0;
            incrementY(textPort);
        }
    }
    else
    {
        textPort->cursor.x++;
    }
    
    if (textPort != &_port) _port.cursor = textPort->absoluteCursor();
    
    return textPort->cursor.x;
}

/*
 * decrements cursor.x within the textport.
 * if leftMargin wraps, it will set x = width - 1 and decrementY (which may scroll)
 * if leftMargin does not wrap, it will not be updated.
 *
 * returns the new cursor.x
 */

int Screen::decrementX(TextPort *textPort)
{
    // honors wrap, scroll.
    if (!textPort) textPort = &_port;
    
    
    if (textPort->cursor.x == 0)
    {
        if (textPort->leftMargin == TextPort::MarginWrap)
        {
            textPort->cursor.x = textPort->frame.width() - 1;
            decrementY(textPort);
        }
    }
    else
    {
        textPort->cursor.x--;
    }
    
    if (textPort != &_port) _port.cursor = textPort->absoluteCursor();
    
    return textPort->cursor.x;    
    
}

/*
 * increment cursor.y
 * this is similar to lineFeed, except that it honors the scroll flag
 * at the bottom of the screen.
 * returns the new cursor.y
 */

int Screen::incrementY(TextPort *textPort)
{
    // similar to linefeed, but honors scroll.
    if (!textPort) textPort = &_port;

    if (textPort->scroll)
        return lineFeed(textPort);

    if (textPort->cursor.y < textPort->frame.height() - 1)
        return lineFeed(textPort);
    
    return textPort->cursor.y;    
}


/*
 * decrement cursor.y
 * this is similar to revereseLineFeed, except that it honors the scroll flag
 * at the top of the screen.
 * returns the new cursor.y
 */
int Screen::decrementY(TextPort *textPort)
{
    // similar to reverseLineFeed, but will not scroll.
    if (!textPort) textPort = &_port;

    if (!textPort) textPort = &_port;
    
    if (textPort->scroll) 
        return lineFeed(textPort);
    
    
    if (textPort->cursor.y > 0)
        return reverseLineFeed(textPort);
    
    
    return textPort->cursor.y;   
}


void Screen::setCursor(TextPort *textPort,iPoint point)
{
    setX(textPort, point.x);
    setY(textPort, point.y);
}

void Screen::setCursor(TextPort *textPort, int x, int y)
{
    setX(textPort, x);
    setY(textPort, y);
}

#pragma mark -
#pragma mark Erase

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
        ScreenIterator end = _screen.begin() + y() - 1;
        for (screenIter = _screen.begin(); screenIter < end; ++screenIter)
        {
            std::fill(screenIter->begin(), screenIter->end(), CharInfo(0,0));
        }
        _updates.push_back(iPoint(0,0));
        _updates.push_back(iPoint(width() - 1, y()));
        
        region = EraseLineBeforeCursor;
    }
    
    if (region == EraseAfterCursor)
    {
        ScreenIterator end = _screen.end();
        for (screenIter = _screen.begin() + y() + 1; screenIter < end; ++screenIter)
        {
            std::fill(screenIter->begin(), screenIter->end(), CharInfo(0,0));
        }
        _updates.push_back(iPoint(0, y() + 1));
        _updates.push_back(iPoint(width() - 1, height() - 1));
        
        region = EraseLineAfterCursor;
    }
    
    if (region == EraseLineAll)
    {    
        std::fill(_screen[y()].begin(), _screen[y()].end(), CharInfo(0,0));
        
        _updates.push_back(iPoint(0, y()));
        _updates.push_back(iPoint(width() - 1, y()));
        
        return;
    }
    
    if (region == EraseLineBeforeCursor)
    {
        std::fill(_screen[y()].begin(), _screen[y()].begin() + x() + 1, CharInfo(0,0));
        
        _updates.push_back(iPoint(0, y()));
        _updates.push_back(cursor());
        
        return;        
    }
    
    if (region == EraseLineAfterCursor)
    {
        std::fill(_screen[y()].begin() + x(), _screen[y()].end(), CharInfo(0,0));
        
        _updates.push_back(cursor());     
        _updates.push_back(iPoint(width() - 1, y()));
        
    }
    
    
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

    if (y() == height() - 1)
    {        
        deleteLine(0);
    }
    else
    {
        _port.cursor.y++;
    }
}

/*
 * perform a line feed. This increments Y.  If Y was at the bottom of the 
 * textPort, the textPort scrolls.
 *
 */
int Screen::lineFeed(TextPort *textPort)
{
    
    if (!textPort)
    {
        lineFeed();
        return y();
    }
    

    if (textPort->cursor.y == textPort->frame.height() - 1)
    {
        deleteLine(textPort, 0);
    }
    else
    {
        textPort->cursor.y++;
        if (textPort != &_port) _port.cursor = textPort->absoluteCursor();        
    }
    
    return textPort->cursor.y;
}



/*
 * perform a reverse line feed. This increments Y.  If Y was at the top of the 
 * textPort, the textPort scrolls.
 *
 */
int Screen::reverseLineFeed(TextPort *textPort)
{
    
    if (!textPort)
    {
        reverseLineFeed();
        return y();
    }
    
    
    if (textPort->cursor.y == 0)
    {
        insertLine(textPort, 0);
    }
    else
    {
        textPort->cursor.y--;
        if (textPort != &_port) _port.cursor = textPort->absoluteCursor();        
    }
    
    return textPort->cursor.y;
}



void Screen::reverseLineFeed()
{  
    // moves the cursor down one row, inserting a blank line at the top.
    
    if (y() == 0)
    {
        insertLine(0);
    }
    else
    {
        _port.cursor.y--;
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
    CharInfo ci;
    
    
    if (!textPort) return insertLine(line);
    
    iRect frame(textPort->frame);
    
    int minY = frame.minY();
    int maxY = frame.maxY();
    
    int minX = frame.minX();
    int maxX = frame.maxX();
    
    if (line < 0) return;
    if (line >= frame.height()) return;
        
    // move all subsequent lines forward by 1.
    for (int y = frame.height() - 2; y >= line; --y)
    {
        CharInfoIterator iter;
        
        iter = _screen[minY + y].begin();
        
        std::copy(iter +minX, iter + maxX, _screen[minY + y + 1].begin() + minX);
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
    CharInfo ci;
    
    if (!textPort) return deleteLine(line);
    
    iRect frame(textPort->frame);
    
    int minY = frame.minY();
    int maxY = frame.maxY();
    
    int minX = frame.minX();
    int maxX = frame.maxX();
    
    if (line < 0) return;
    if (line >= frame.height()) return;
    
    // move all subsequent lines back by 1.
    for (int y = line; y < frame.height() - 2; ++y)
    {
        CharInfoIterator iter;
        CharInfoIterator end;
        
        iter = _screen[minY + y + 1].begin();
        
        std::copy(iter + minX, iter + maxX, _screen[minY + y].begin() + minX);
    }
    
    // clear the last line.
    std::fill(_screen[maxY - 1].begin() + minX, _screen[maxY - 1].begin() + maxX, ci);
    
    // set the update region.
    
    _updates.push_back(iPoint(minX, minY + line));
    _updates.push_back(iPoint(maxX - 1, maxY - 1));
    
}



void Screen::setSize(unsigned w, unsigned h)
{
    // TODO -- have separate minimum size for textport?

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


    if (_port.cursor.y >= h) _port.cursor.y = h - 1;
    if (_port.cursor.x >= w) _port.cursor.x = w - 1;
    
    //fprintf(stderr, "setSize(%u, %u)\n", width, height);
        
}