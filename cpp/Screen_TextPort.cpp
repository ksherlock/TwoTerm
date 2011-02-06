//
//  Screen_TextPort.cpp
//  2Term
//
//  Created by Kelvin Sherlock on 1/11/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "Screen.h"



void Screen::setTextPort(const TextPort& textPort)
{
    TextPort tmp(textPort);
    
    // call virtual method...
    setSize(textPort.frame.width(), textPort.frame.height());
    
    tmp.frame.origin = iPoint(0, 0);
    _port = tmp;
}

/*
 * Non-destructive tab.
 * Sets the horizontal cursor position, may wrap and scroll
 *
 *
 */
void Screen::tabTo(TextPort *textPort, unsigned xPos)
{
    
    if (!textPort) textPort = &_port;
    
    iRect frame = textPort->frame;
    
    // best case -- no wrapping needed.
    if (xPos < frame.width())
    {
        textPort->cursor.x = xPos;

    }
    else if (textPort->rightMargin == TextPort::MarginWrap)
    {
        // worst case -- wrapping needed.
        textPort->cursor.x = 0;
        incrementY(textPort);

        if (textPort != &_port) _port.cursor = textPort->absoluteCursor();
        
        return;
    }
    else
    {
        // clamp to right margin.
        textPort->cursor.x = frame.width() - 1;
    }

    if (textPort != &_port) _port.cursor = textPort->absoluteCursor();
    
    return;
}

// insert a character at the current cursor position,
// moving all characters right 1.
// no wrapping is performed.
void Screen::insertc(TextPort *textPort, uint8_t c)
{
    if (!textPort) textPort = &_port;
    
    iRect frame = textPort->frame;
    iPoint cursor = textPort->cursor;
    iPoint absoluteCursor = textPort->absoluteCursor();
    
    if (cursor.x >= frame.width()) return;
    if (cursor.y >= frame.height()) return;
    
    CharInfoIterator iter = _screen[absoluteCursor.y].begin();
    CharInfoIterator begin = iter + absoluteCursor.x;
    CharInfoIterator end = iter + frame.maxX();
    
    CharInfo ci(c, _flag);
    // move all chars forward 1.
    for (iter = begin; iter < end; ++iter)
    {
        std::swap(ci, *iter);
    }
    
    _updates.push_back(absoluteCursor);
    _updates.push_back(iPoint(frame.maxX(), absoluteCursor.y));
}

// delete the character at the current cursor position,
// moving any character to the right left 1 spot
// the final position is blank filled.
// no wrapping is performed.
void Screen::deletec(TextPort *textPort)
{
    if (!textPort) textPort = &_port;
    
    iRect frame = textPort->frame;
    iPoint cursor = textPort->cursor;
    iPoint absoluteCursor = textPort->absoluteCursor();
    
    if (cursor.x >= frame.width()) return;
    if (cursor.y >= frame.height()) return;
    
    CharInfoIterator iter = _screen[absoluteCursor.y].begin();
    CharInfoIterator begin = iter + absoluteCursor.x;
    CharInfoIterator end = iter + frame.maxX() - 1;
    

    for (iter = begin; iter < end; ++iter)
    {
        iter[0] = iter[1];
        
    }
    
    // not sure about the flag situation...
    *iter = CharInfo(' ', _flag);
    
    _updates.push_back(absoluteCursor);
    _updates.push_back(iPoint(frame.maxX(), absoluteCursor.y));    
}