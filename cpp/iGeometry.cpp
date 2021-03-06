/*
 *  iGeometry.cpp
 *  2Term
 *
 *  Created by Kelvin Sherlock on 7/10/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */


#include "iGeometry.h"
#include <algorithm>

bool iRect::contains(const iPoint aPoint) const
{
    return aPoint.x >= origin.x
    && aPoint.y >= origin.y
    && aPoint.x <= origin.x + size.width
    && aPoint.y <= origin.y + size.height;    
}

bool iRect::contains(const iRect aRect) const
{
    return aRect.origin.x >= origin.x
    && aRect.origin.y >= origin.y
    && aRect.origin.x + aRect.size.width <= origin.x + size.width
    && aRect.origin.y + aRect.size.height <= origin.y + size.height;
}

bool iRect::intersects(const iRect aRect) const
{
    return aRect.contains(origin) || aRect.contains(origin.offset(size));    
}

iRect iRect::intersection(const iRect &rhs) const {
    iPoint topLeft;
    iPoint bottomRight;
    topLeft.x = std::max(origin.x, rhs.origin.x);
    topLeft.y = std::max(origin.y, rhs.origin.y);

    bottomRight.x = std::min(maxX(), rhs.maxX());
    bottomRight.y = std::min(maxY(), rhs.maxY());
    
    if (bottomRight.x <= topLeft.x) return iRect();
    if (bottomRight.y <= topLeft.y) return iRect();
    
    return iRect(topLeft, bottomRight);
}
