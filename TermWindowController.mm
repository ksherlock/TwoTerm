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
#include <errno.h>
#include <sys/ttydefaults.h>

#include <string>
#include <vector>

@implementation TermWindowController

@synthesize emulator = _emulator;

+(id)new
{
    return [[self alloc] initWithWindowNibName: @"TermWindow"];
}

-(void)dealloc
{    
    [_emulator release];
    [_emulatorView release];
    
    [super dealloc];
}

/*
-(void)awakeFromNib
{
    [self initPTY];
}
*/

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
        
        std::vector<const char *> environ;
        std::string s;
        ;
            
        s.append("TERM_PROGRAM=2Term");
        s.append(1, (char)0);
        
        s.append("LANG=C");
        s.append(1, (char)0); 
        
        s.append("TERM=");
        s.append([_emulator termName]);
        
        s.append(1, (char)0); 
        s.append(1, (char )0);
        
        for (std::string::size_type index = 0;;)
        {
            environ.push_back(&s[index]);

            index = s.find((char)0, index);
            if (index == std::string::npos) break;
            
            if (s[++index] == 0) break;
            
        }
        
        environ.push_back(NULL);
        
        
        // call login -f [username]
        // -p -- do NOT ignore environment.
        // export TERM=...
        
        
        // TODO -- option for localhost, telnet, ssh, etc.
        execle("/usr/bin/login", "login", "-pf", getlogin(), NULL, &environ[0]);
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


#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowDidLoad
{
    NSWindow *window = [self window];

    [super windowDidLoad];
    
    
    [window setTitle: [_emulator name]];
    [_emulatorView setEmulator: _emulator];
    
    [self initPTY];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [self autorelease];
}

@end
