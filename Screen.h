/*
 *  Screen.h
 *  2Term
 *
 *  Created by Kelvin Sherlock on 7/7/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __SCREEN_H__
#define __SCREEN_H__

#include "iGeometry.h"

#include <vector>

typedef struct CharInfo {
    
    CharInfo() : c(0), flag(0) {}
    CharInfo(uint8_t cc, uint8_t ff) : c(cc), flag(ff) {}
    
    uint8_t c;
    uint8_t flag;
    
} CharInfo;

class Screen {
    
public:

    Screen(unsigned height, unsigned width);
    
    int x() const;
    int y() const;
    
    iPoint cursor() const;
    uint8_t flag() const;
    
    unsigned height() const;
    unsigned width() const;
    
    
    int incrementX(bool clamp = true);
    int decrementX(bool clamp = true);
    int incrementY(bool clamp = true);
    int decrementY(bool clamp = true);
    
    void setX(int x, bool clamp = true);
    void setY(int y, bool clamp = true);
    
    void setCursor(iPoint point, bool clampX = true, bool clampY = true);
    void setCursor(int x, int y, bool clampX = true, bool clampY = true);
    
    void setFlag(uint8_t flag);
    
    void putc(uint8_t c, bool incrementX = true);
    
    void eraseLine();
    void eraseScreen();
    
    void lineFeed();
    void reverseLineFeed();
    
    
    void beginUpdate();
    iRect endUpdate();
    
private:
    
    iPoint _cursor;
    unsigned _height;
    unsigned _width;
    
    uint8_t _flag;
    
    std::vector< std::vector< CharInfo > > _screen; 
    
    std::vector<iPoint> _updates;
    
    
    typedef std::vector< std::vector< CharInfo > >::iterator ScreenIterator;
    typedef std::vector< std::vector< CharInfo > >::reverse_iterator ReverseScreenIterator;

    typedef std::vector<CharInfo>::iterator CharInfoIterator;
    typedef std::vector<iPoint>::iterator UpdateIterator;
    
};


int Screen::x() const
{
    return _cursor.x;
}

int Screen::y() const 
{
    return _cursor.y;
}

iPoint Screen::cursor() const
{
    return _cursor;
}

uint8_t Screen::flag() const
{
    return _flag;
}

unsigned Screen::height() const
{
    return _height;
}

unsigned Screen::width() const
{
    return _width;
}

void Screen::setCursor(iPoint point, bool clampX, bool clampY)
{
    setX(point.x, clampX);
    setY(point.y, clampY);
}

void Screen::setCursor(int x, int y, bool clampX, bool clampY)
{
    setX(x, clampX);
    setY(y, clampY);
}


#endif
