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


typedef struct iPoint {
    
    int x;
    int y;
    
#ifdef __cplusplus
    iPoint() : x(0), y(0) {}
    iPoint(const iPoint &aPoint) : x(aPoint.x), y(aPoint.y) {}
    iPoint(int xx, int yy) : x(xx), y(yy) {} 
#endif
    
} iPoint;


typedef struct iSize {
    
    int width;
    int height;
    
#ifdef __cplusplus
    iSize() : width(0), height(0) {}
    iSize(const iSize &aSize) : width(aSize.width), height(aSize.width) {}
    iSize(int w, int h) : width(w), height(h) {} 
#endif
    
} iSize;


typedef struct iRect {
    iPoint origin;
    iSize size;
    
#ifdef __cplusplus
    iRect() {}
    iRect(const iRect &aRect) : origin(aRect.origin), size(aRect.size) {}
    iRect(const iPoint &aPoint, const iSize &aSize) : origin(aPoint), size(aSize) {}
#endif
    
} iRect;

#endif
