//
//  TermWindowController.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TermWindowController.h"
#import "EmulatorView.h"

#define TTYDEFCHARS

#include <util.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <errno.h>
#include <sys/ttydefaults.h>

@implementation TermWindowController

+(id)new
{
    return [[self alloc] initWithWindowNibName: @"TermWindow"];
}

-(void)awakeFromNib
{
    [self initPTY];
}

-(void)initPTY
{
    int pid;
    int fd;
    struct termios term;
    struct winsize ws = { 24, 80, 0, 0 };
    //int flags;
    
    memset(&term, 0, sizeof(term));
    
    //term.c_oflag = OPOST | ONLCR;
    //term.c_lflag = ECHO;
    //term.c_iflag = ICRNL; // | ICANON | ECHOE | ISIG;
    
    term.c_oflag = TTYDEF_OFLAG;
    term.c_lflag = TTYDEF_LFLAG;
    term.c_iflag = TTYDEF_IFLAG;
    term.c_cflag = TTYDEF_CFLAG;
    
    term.c_ispeed = term.c_ospeed = TTYDEF_SPEED;  
    
    memcpy(term.c_cc, ttydefchars, sizeof(ttydefchars));
  
    
    
    pid = forkpty(&fd, NULL, &term, &ws);
    
    if (pid < 0)
    {
        //error
        return;
    }
    if (pid == 0)
    {
        const char *environ[] = {
            "TERM=vt100",
            "LANG=C",
            "TERM_PROGRAM=2Term",
            NULL
        };
        // call login -f [username]
        // export TERM=...
        
        
        
        execle("/usr/bin/login", "login", "-f", "kelvin", NULL, environ);
        fprintf(stderr, "execle failed\n");
        fflush(stderr);
        
        exit(-1);
        // child
    }

    /*
    if (fcntl(fd, F_GETFL, &flags) < 0) flags = 0;
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    */

    _child = pid;
    
    [_emulatorView setFd: fd];
    [_emulatorView startBackgroundReader];
}


@end
