//
//  algorithm_17.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/12/2016.
//
//

#ifndef algorithm_17_h
#define algorithm_17_h

#include <algorithm>


// c++17

template<class T, class Compare>
constexpr const T& clamp( const T& v, const T& lo, const T& hi, Compare comp ) {
    return comp(v, hi) ? std::max(v, lo, comp) : std::min(v, hi, comp);
}

template<class T>
constexpr const T& clamp( const T& v, const T& lo, const T& hi ) {
    return clamp( v, lo, hi, std::less<T>() );
}


#endif /* algorithm_17_h */
