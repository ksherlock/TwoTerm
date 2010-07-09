/*
 *  Benaphore.h
 *  Blue Box
 *
 *  Created by Kelvin Sherlock on 11/29/2009.
 *  Copyright 2009 Kelvin W Sherlock LLC. All rights reserved.
 *
 */

#ifndef __BENAPHORE_H__
#define __BENAPHORE_H__

#include <stdint.h>
#include <mach/semaphore.h>


class Benaphore {
public:
    Benaphore();
    ~Benaphore();
    
    void lock();
    void unlock();
private:
    int32_t _atom;
    semaphore_t _sem;
    
};

class Locker {
public:
    Locker(Benaphore& lock) : _lock(lock) { _lock.lock(); }
    ~Locker() { _lock.unlock(); }
    
private:
    Benaphore& _lock;
};

#endif