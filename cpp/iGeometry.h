/*
 *  iGeometry.h
 *  2Term
 *
 *  Created by Kelvin Sherlock on 7/7/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __IGEOMETRY_H__
#define __IGEOMETRY_H__



typedef struct iSize {
    
    int width = 0;
    int height = 0;
    
    iSize() = default;
    iSize(const iSize &) = default;
    iSize(int w, int h) : width(w), height(h) {} 
    
    iSize &operator=(const iSize &) = default;

    bool operator==(const iSize &aSize) const
    { return width == aSize.width && height == aSize.height; }
    
    bool operator!=(const iSize& aSize) const
    { return !(*this == aSize); }
    
} iSize;


typedef struct iPoint {
    
    int x = 0;
    int y = 0;
    
    iPoint() = default;
    iPoint(const iPoint &aPoint) = default;
    iPoint(int xx, int yy) : x(xx), y(yy) {} 
    
    iPoint &operator=(const iPoint &) = default;
    
    bool operator==(const iPoint &aPoint) const
    { return x == aPoint.x && y == aPoint.y; }
    
    bool operator!=(const iPoint &aPoint) const
    { return !(*this == aPoint); }
    
    iPoint offset(int dx, int dy) const
    { return iPoint(x + dx, y + dy); }
    
    iPoint offset(iSize aSize) const
    { return iPoint(x + aSize.width, y + aSize.height); }

} iPoint;



typedef struct iRect {
    iPoint origin;
    iSize size;
    
    iRect() = default;
    iRect(const iRect &aRect) = default;

    iRect(const iPoint &aPoint, const iSize &aSize) : origin(aPoint), size(aSize) {}
    iRect(int x, int y, int width, int height) : origin(x, y), size(width, height) {}
    
    iRect(const iPoint &topLeft, const iPoint &bottomRight) :
        origin(topLeft), size(bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
    {}
    
    iRect &operator=(const iRect &) = default;
    
    bool contains(const iPoint aPoint) const;
    bool contains(const iRect aRect) const;
    
    bool intersects(const iRect aRect) const;
    
    iRect intersection(const iRect &rhs) const;
    
    bool operator==(const iRect &rhs) const {
        return origin == rhs.origin && size == rhs.size;
    }
    bool operator!=(const iRect &rhs) const {
        return !(*this == rhs);
    }
    
    explicit operator bool() const { return size.height >= 0 && size.width >= 0; }
    bool operator!() const { return size.height < 0 || size.width < 0; }
    bool valid() const { return size.height >= 0 && size.width >= 0; }
    
    iPoint topLeft() const { return origin; }
    iPoint bottomRight() const { return iPoint(maxX(), maxY()); }
    
    void setBottomLeft(iPoint &p);
    
    int height() const
    { return size.height; }
    
    int width() const
    { return size.width; }
    
    int minX() const
    { return origin.x; }
    
    int minY() const
    { return origin.y; }
    
    int maxX() const
    { return minX() + width(); }
    
    int maxY() const
    { return minY() + height(); }
        
    
} iRect;

#endif
