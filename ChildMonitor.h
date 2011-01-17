//
//  ChildMonitor.h
//  2Term
//
//  Created by Kelvin Sherlock on 1/16/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

/*
 * An NSThread to monitor a pid and fd.
 * requires 10.5+
 *
 */

#import <Foundation/Foundation.h>

@class ChildMonitor;

@protocol ChildMonitorDelegate

-(void)childDataAvailable: (ChildMonitor *)monitor;
-(void)childFinished: (ChildMonitor *)monitor;

@end

@interface ChildMonitor : NSThread {

    pid_t _childPID;
    int _fd;
    int _childStatus;
    BOOL _childFinished;
    
    id<ChildMonitorDelegate> _delegate; 
    
}

@property (assign) BOOL childFinished;
@property (assign) int childStatus;
@property (nonatomic, assign) pid_t childPID;
@property (nonatomic, assign) int fd;

@property (nonatomic, assign) id<ChildMonitorDelegate> delegate;

@end
