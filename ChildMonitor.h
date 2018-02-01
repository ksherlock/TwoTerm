//
//  ChildMonitor.h
//  TwoTerm
//
//  Created by Kelvin Sherlock on 1/31/2018.
//

#import <Foundation/Foundation.h>

@class TermWindowController;
@interface ChildMonitor : NSObject {

}

+(id)monitor;

-(void)removeController: (TermWindowController *)controller;
-(void)addController: (TermWindowController *)controller pid: (pid_t)pid fd: (int)fd;

@end
