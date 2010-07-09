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
#include "Lock.h"

#include <vector>



typedef struct CharInfo {
    
    CharInfo() : c(0), flag(0) {}
    CharInfo(uint8_t cc, uint8_t ff) : c(cc), flag(ff) {}
    
    uint8_t c;
    uint8_t flag;
    
} CharInfo;

class Screen {
    
public:

    Screen(unsigned height = 24, unsigned width = 80);
    
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
    
    CharInfo getc(int x, int y) const;
    
    void eraseLine();
    void eraseScreen();
    
    void lineFeed();
    void reverseLineFeed();
    
    
    void beginUpdate();
    iRect endUpdate();
    
    
    void lock();
    void unlock();
    
private:
    
    iPoint _cursor;
    unsigned _height;
    unsigned _width;
    
    uint8_t _flag;
    
    
    Lock _lock;
    
    std::vector< std::vector< CharInfo > > _screen; 
    
    std::vector<iPoint> _updates;
    
    
    typedef std::vector< std::vector< CharInfo > >::iterator ScreenIterator;
    typedef std::vector< std::vector< CharInfo > >::reverse_iterator ReverseScreenIterator;

    typedef std::vector<CharInfo>::iterator CharInfoIterator;
    typedef std::vector<iPoint>::iterator UpdateIterator;
    
};


inline int Screen::x() const
{
    return _cursor.x;
}

inline int Screen::y() const 
{
    return _cursor.y;
}

inline iPoint Screen::cursor() const
{
    return _cursor;
}

inline uint8_t Screen::flag() const
{
    return _flag;
}

inline unsigned Screen::height() const
{
    return _height;
}

inline unsigned Screen::width() const
{
    return _width;
}

inline void Screen::setCursor(iPoint point, bool clampX, bool clampY)
{
    setX(point.x, clampX);
    setY(point.y, clampY);
}

inline void Screen::setCursor(int x, int y, bool clampX, bool clampY)
{
    setX(x, clampX);
    setY(y, clampY);
}


inline void Screen::lock()
{
    _lock.lock();
}

inline void Screen::unlock()
{
    _lock.unlock();
}


inline CharInfo Screen::getc(int x, int y) const
{
    if (x < 0 || y < 0) return CharInfo(0,0);
    if (x >= _width || y >= _height) return CharInfo(0,0);
    
    return _screen[y][x];
}

#endif
