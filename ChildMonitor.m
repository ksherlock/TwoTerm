//
//  ChildMonitor.m
//  2Term
//
//  Created by Kelvin Sherlock on 1/16/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChildMonitor.h"

#include <sys/wait.h>
#include <sys/select.h>
#include <signal.h>

@implementation ChildMonitor

@synthesize childFinished = _childFinished;
@synthesize childStatus = _childStatus;
@synthesize childPID = _childPID;
@synthesize fd = _fd;
@synthesize delegate = _delegate;

-(BOOL)wait
{
    int status = 0;

    if (waitpid(_childPID, &status, WNOHANG) == _childPID)
    {
        [self setChildStatus: status];
        [self setChildFinished: YES];
        
        [(NSObject *)_delegate performSelectorOnMainThread: @selector(childFinished:) 
                                                withObject: self 
                                             waitUntilDone: NO];
        
        return YES;
    }
 
    return  NO;
}

-(void)main
{
    int fd = _fd;
        
    // poll(2) does not work for ptys.
    // todo -- check if kqueue works with ptys
    // kqueue can also monitor the child process.
    
    
    for(;;)
    {
        int n;
        
        struct timeval tm;
        
        fd_set read_set;
        fd_set error_set;

        
        if ([self isCancelled]) break;

        
        FD_ZERO(&read_set);
        FD_SET(fd, &read_set);
        FD_ZERO(&error_set);
        FD_SET(fd, &error_set);    
        
        // 10 second timeout...
        tm.tv_sec = 10;
        tm.tv_usec = 0;
        
        errno = 0;
        n = select(fd + 1, &read_set, NULL, &error_set, &tm);
        
        //NSLog(@"select: %d %d", n, errno);
        if (n == 0) continue;
        if (n < 0) break;
        
        if (FD_ISSET(fd, &error_set)) break;
        // ?
        
        if (FD_ISSET(fd, &read_set))
        {
            [_delegate childDataAvailable: self];
        }
        
        if ([self wait]) break;
        
    }
    
    if (!_childFinished) [self wait];
}


- (void)dealloc {
    
    if (!_childFinished) kill(_childPID, 9);
    [super dealloc];
}

@end
