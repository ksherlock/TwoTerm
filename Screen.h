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


typedef struct TextPort {

    enum RightMargin {
        RMTruncate,
        RMWrap,
        RMOverwrite
    };
    
    
        
    iRect frame;


    RightMargin rightMargin;
    
    bool advanceCursor;
    //bool lineFeed;
    bool scroll;
    

};

class Screen {
    
public:

    static const unsigned FlagNormal = 0x00;
    static const unsigned FlagInverse = 0x01;
    static const unsigned FlagMouseText = 0x02;
    static const unsigned FlagBold = 0x04;
    static const unsigned FlagUnderscore = 0x08;
    static const unsigned FlagBlink = 0x10;
    static const unsigned FlagSelected = 0x8000;
    
    

    enum EraseRegion {
        EraseAll,
        EraseBeforeCursor,
        EraseAfterCursor,
        
        EraseLineAll,
        EraseLineBeforeCursor,
        EraseLineAfterCursor
    };
    
    Screen(unsigned height = 24, unsigned width = 80);


    
    virtual ~Screen();
    
    
    int x() const;
    int y() const;
    
    iPoint cursor() const;
    uint8_t flag() const;
    
    int height() const;
    int width() const;
    
    
    int incrementX(bool clamp = true);
    int decrementX(bool clamp = true);
    int incrementY(bool clamp = true);
    int decrementY(bool clamp = true);
    
    void setX(int x, bool clamp = true);
    void setY(int y, bool clamp = true);
    
    void setCursor(iPoint point, bool clampX = true, bool clampY = true);
    void setCursor(int x, int y, bool clampX = true, bool clampY = true);

    
    void setFlag(uint8_t flag);
    void setFlagBit(uint8_t bit);
    void clearFlagBit(uint8_t bit);
    
    
    void putc(uint8_t c, bool incrementX = true);
    CharInfo getc(int x, int y) const;
    
    void deletec();
    void insertc(uint8_t c);
    
    void tabTo(unsigned x);
    
    
    
    void erase(EraseRegion);
    
    void eraseLine();
    void eraseScreen();
    
    void eraseRect(iRect rect);
    
    
    void lineFeed();
    void lineFeed(TextPort *textPort);

    void reverseLineFeed();
    void reverseLineFeed(TextPort *textPort);
    
    
    
    void deleteLine(unsigned line);
    void insertLine(unsigned line);
    
    void insertLine(TextPort *textPort, unsigned line);
    void deleteLine(TextPort *textPort, unsigned line);

    
    void beginUpdate();
    iRect endUpdate();
    
    
    void lock();
    void unlock();
    
    
    virtual void setSize(unsigned width, unsigned height);

    
private:
    
    iPoint _cursor;
    
    TextPort _port;    

    
    uint8_t _flag;
    
    
    Lock _lock;
    
    std::vector< std::vector< CharInfo > > _screen; 
    
    std::vector<iPoint> _updates;
    iPoint _updateCursor;
    
    
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

inline int Screen::height() const
{
    return _port.frame.size.height;
}

inline int Screen::width() const
{
    return _port.frame.size.width;
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
    if (x >= width() || y >= height()) return CharInfo(0,0);
    
    return _screen[y][x];
}

#endif
