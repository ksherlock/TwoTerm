/*
 *  Benaphore.cpp
 *  Blue Box
 *
 *  Created by Kelvin Sherlock on 11/29/2009.
 *  Copyright 2009 Kelvin W Sherlock LLC. All rights reserved.
 *
 */

#include "Benaphore.h"

#include <libkern/OSAtomic.h>
#include <mach/semaphore.h>
#include <mach/task.h>
#include <mach/mach_init.h>

#include <cstdio>

Benaphore::Benaphore()
{
    _atom = 0;
    semaphore_create(mach_task_self(), (semaphore_t *)&_sem, SYNC_POLICY_FIFO, 0);
}

Benaphore::~Benaphore()
{
    semaphore_destroy(mach_task_self(), (semaphore_t)_sem);

}
void Benaphore::lock()
{
    // returns new value
    if (OSAtomicIncrement32Barrier(&_atom) > 1)
    {
        fprintf(stderr, "waiting %u\n", _atom);
        semaphore_wait((semaphore_t)_sem);
    }
}

void Benaphore::unlock()
{
    if (OSAtomicDecrement32Barrier(&_atom) > 0)
    {
        fprintf(stderr, "releasing %u\n", _atom);
        semaphore_signal((semaphore_t)_sem);
    }
        
}