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
    
    int width;
    int height;
    
#ifdef __cplusplus
    iSize() : width(0), height(0) {}
    iSize(const iSize &aSize) : width(aSize.width), height(aSize.width) {}
    iSize(int w, int h) : width(w), height(h) {} 
    

    bool operator==(const iSize &aSize)
    { return width == aSize.width && height == aSize.height; }
    
    bool operator!=(const iSize& aSize)
    { return !(*this == aSize); }
#endif
    
} iSize;


typedef struct iPoint {
    
    int x;
    int y;
    
#ifdef __cplusplus
    iPoint() : x(0), y(0) {}
    iPoint(const iPoint &aPoint) : x(aPoint.x), y(aPoint.y) {}
    iPoint(int xx, int yy) : x(xx), y(yy) {} 
    
    bool operator==(const iPoint &aPoint)
    { return x == aPoint.x && y == aPoint.y; }
    
    bool operator!=(const iPoint &aPoint)
    { return !(*this == aPoint); }
    
    iPoint offset(int dx, int dy) const
    { return iPoint(x + dx, y + dy); }
    
    iPoint offset(iSize aSize) const
    { return iPoint(x + aSize.width, y + aSize.height); }
        
#endif
    
} iPoint;



typedef struct iRect {
    iPoint origin;
    iSize size;
    
#ifdef __cplusplus
    iRect() {}
    iRect(const iRect &aRect) : origin(aRect.origin), size(aRect.size) {}
    iRect(const iPoint &aPoint, const iSize &aSize) : origin(aPoint), size(aSize) {}
    iRect(int x, int y, int width, int height) : origin(iPoint(x, y)), size(iSize(width, height)) {}
    
    bool contains(const iPoint aPoint) const;
    bool contains(const iRect aRect) const;
    
    bool intersects(const iRect aRect) const;
    
    
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
        
    
#endif
    
} iRect;

#endif
