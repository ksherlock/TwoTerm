/*
 *  OutputChannel.cpp
 *  2Term
 *
 *  Created by Kelvin Sherlock on 7/7/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "OutputChannel.h"

#include <unistd.h>
#include <fcntl.h>
#include <cstring>
#include <cerrno>

bool OutputChannel::write(uint8_t c)
{
    return write(&c, 1);
}

bool OutputChannel::write(const char *str)
{    
    return write(str, std::strlen(str));
}

bool OutputChannel::write(const void *vp, size_t size)
{
    
    if (!size) return true;
    
    for (unsigned i = 0; ;)
    {
        ssize_t s = ::write(_fd, vp, size);
        
        if (s < 0)
        {
            switch (errno)
            {
                case EAGAIN:
                case EINTR:
                    if (++i < 3) break;
                default:
                    _error = errno;
                    // throw?
                    return false;
            }
        
        }

        else if (size == s)
        {
            return true; 
        }
        
        else if (s == 0)
        {
            if (++i == 3)
            {
                _error = EIO;
                return false;
            }
        }        
        else
        {
            size -= s;
            vp = (uint8_t *)vp + s;
            
            if (size == 0) return true;
        }

    }
    
    return false;
}