/*
 *  OutputChannel.h
 *  2Term
 *
 *  Created by Kelvin Sherlock on 7/7/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __OUTPUT_CHANNEL_H__
#define __OUTPUT_CHANNEL_H__

#include <stdint.h>
#include <sys/types.h>

class OutputChannel
{
public:
    OutputChannel(int fd) : _fd(fd), _error(0) {};
    
    bool write(uint8_t);
    bool write(const char *);
    bool write(const void *, size_t);
    
    int error() const { return _error; }
    
private:
    OutputChannel(const OutputChannel&);
    OutputChannel& operator=(const OutputChannel&);
    
    int _fd;
    int _error;
};


#endif