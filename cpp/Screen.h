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



typedef struct char_info {
    
    char_info() = default;
    char_info(uint8_t cc, uint8_t ff) : c(cc), flag(ff) {}
    
    uint8_t c = 0;
    uint8_t flag = 0;
    
} char_info;


typedef struct context {
    uint8_t flags = 0;
    iRect window;
    iPoint cursor;
    
    void setFlagBit(unsigned x) { flags |= x; }
    void clearFlagBit(unsigned x) { flags &= ~x; }
} context;



class Screen {
    
public:

    static const unsigned FlagNormal = 0x00;
    static const unsigned FlagInverse = 0x01;
    static const unsigned FlagMouseText = 0x02;
    static const unsigned FlagBold = 0x04;
    static const unsigned FlagUnderscore = 0x08;
    static const unsigned FlagBlink = 0x10;
    static const unsigned FlagStrike = 0x20;
    
    static const unsigned FlagSelected = 0x8000;
    
    
/*
    enum EraseRegion {
        EraseAll,
        EraseBeforeCursor,
        EraseAfterCursor,
        
        EraseLineAll,
        EraseLineBeforeCursor,
        EraseLineAfterCursor
    };
*/
    enum CursorType {
        CursorTypeNone,
        CursorTypeUnderscore,
        CursorTypePipe,
        CursorTypeBlock
    };
    
    Screen(unsigned height = 24, unsigned width = 80);


    
    virtual ~Screen();
    
    
    int x() const;
    int y() const;
    
    iPoint cursor() const;
    
    int height() const;
    int width() const;
    
    
    void setCursor(iPoint point);



    void putc(uint8_t c, iPoint cursor, uint8_t flags = 0);
    void putc(uint8_t c, const context &ctx) { putc(c, ctx.cursor, ctx.flags); }

    char_info getc(iPoint p) const;

    
    void eraseScreen();
    void eraseRect(iRect rect);
    
    
    void scrollUp();
    void scrollUp(iRect window);
    
    void scrollDown();
    void scrollDown(iRect window);
    
    
    
    void deleteLine(unsigned line);
    void insertLine(unsigned line);
    
    //void deletec();
    //void insertc(uint8_t c);

    void beginUpdate();
    iRect endUpdate();
    
    
    void lock();
    void unlock();
    
    virtual void setSize(unsigned width, unsigned height);
    
    virtual void setCursorType(CursorType cursor);
    CursorType cursorType() const;

    
private:
        
    iRect _frame;
    iPoint _cursor;
    
    CursorType _cursorType;
    
    
    Lock _lock;
    
    std::vector< std::vector< char_info > > _screen;
    
    std::vector<iPoint> _updates;
    iPoint _updateCursor;
    
    
    typedef std::vector< std::vector< char_info > >::iterator ScreenIterator;
    typedef std::vector< std::vector< char_info > >::reverse_iterator ReverseScreenIterator;

    typedef std::vector<char_info>::iterator CharInfoIterator;
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


inline Screen::CursorType Screen::cursorType() const
{
    return _cursorType;
}

inline int Screen::height() const
{
    return _frame.size.height;
}

inline int Screen::width() const
{
    return _frame.size.width;
}

inline void Screen::setCursor(iPoint point)
{
    _cursor = point;
}


inline void Screen::lock()
{
    _lock.lock();
}

inline void Screen::unlock()
{
    _lock.unlock();
}


inline char_info Screen::getc(iPoint p) const
{
    if (_frame.contains(p)) return _screen[p.y][p.x];
    return char_info();
}

#endif
