//
//  TermWindowController.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TermWindowController.h"
#import "EmulatorView.h"
#import "CurveView.h"
#import "EmulatorWindow.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <atomic>


#import "Defaults.h"


#define TTYDEFCHARS

#include <util.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ttydefaults.h>

#include <string>
#include <vector>

#include "ChildMonitor.h"

@implementation TermWindowController

@synthesize emulator = _emulator;
@synthesize emulatorView = _emulatorView;
@synthesize colorView = _colorView;

@synthesize parameters = _parameters;

+(id)new
{
    return [[self alloc] initWithWindowNibName: @"TermWindow"];
}

-(void)dealloc
{
    [[ChildMonitor monitor] removeController: self];
    
    [_emulator release];
    [_emulatorView release];
    [_colorView release];

    [_parameters release];
    
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
    static std::string username;
    
    pid_t pid;
    int fd;

    struct termios term;
    struct winsize ws = [_emulator defaultSize];
    
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
  
    if ([_emulator respondsToSelector: @selector(initTerm:)])
        [_emulator initTerm: &term];
    
    
    // getlogin() sometimes returns crap.
    if (username.empty()) {
        username = [NSUserName() UTF8String];
    }
    //NSLog(@"%@ %s %s", NSUserName(), getlogin(), getpwent()->pw_name);
   pid = forkpty(&fd, NULL, &term, &ws);
    
    if (pid < 0)
    {
        fprintf(stderr, "forkpty failed\n");
        fflush(stderr);
        
        return;
    }
    if (pid == 0)
    {
        
        std::vector<const char *> environ;
        std::string s;
        
            
        s.append("TERM_PROGRAM=TwoTerm");
        s.append(1, (char)0);
        
        s.append("LANG=C");
        s.append(1, (char)0); 
        
        s.append("TERM=");
        s.append([_emulator termName]);
        
        s.append(1, (char)0); 
        s.append(1, (char)0);
        
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
        execle("/usr/bin/login", "login", "-pf", username.c_str(), NULL, &environ[0]);
        
        fprintf(stderr, "execle failed: %s\n", strerror(errno));
        fflush(stderr);
        
        // should not call exit.
        _exit(-1);
        // child
    }


    if ([_emulator respondsToSelector: @selector(displaySize)]) {
        ws = [_emulator displaySize];
    }
    
    [_emulatorView resizeTo: iSize(ws.ws_col, ws.ws_row) animated: NO];


    NSWindow *window = [self window];

    if (![_emulator resizable])
    {
        
        NSUInteger mask = [window styleMask];
        
        
        [window setShowsResizeIndicator: NO];
        
        [window setStyleMask: mask & ~NSResizableWindowMask];
    }

    [window setMinSize: [window frame].size];

    [_emulatorView setFd: fd];

    [[ChildMonitor monitor] addController: self pid: pid fd: fd];
}


-(void)childFinished: (int)status {
    [_emulatorView childFinished: status];
}

-(void)processData: (const void *)buffer size: (size_t)size {
    [_emulatorView processData: (uint8_t *)buffer size: size];
}

#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowDidLoad
{
    
    NSColor *foregroundColor;
    NSColor *backgroundColor;
    Class klass;
    id o;
    
    NSWindow *window;
    
    [super windowDidLoad];
    
    window = [self window];
    
    //[(CurveView *)[window contentView] setColor: [NSColor clearColor]];
    
    //[window setContentView: _curveView];
    
    // resize in 2.0 height increments to prevent jittering the scan lines.
    //[window setResizeIncrements: NSMakeSize(1.0, 2.0)];
    
    
    klass = [_parameters objectForKey: kClass];
    if (!klass || ![klass conformsToProtocol: @protocol(Emulator)])
    {
        klass = Nil;
        //klass = [VT52 class];
    }
    
    o = [_parameters objectForKey: kForegroundColor];
    foregroundColor = o ? (NSColor *)o : [NSColor greenColor];
    
    o = [_parameters objectForKey: kBackgroundColor];
    backgroundColor = o ? (NSColor *)o : [NSColor blackColor];
    
    
    [self willChangeValueForKey: @"emulator"];
    _emulator = [klass new];
    [self didChangeValueForKey: @"emulator"];

    [window setBackgroundColor: backgroundColor];
    [(EmulatorWindow *)window setTitleTextColor: foregroundColor];

    [_emulatorView setEmulator: _emulator];
    [_emulatorView setForegroundColor: foregroundColor];
    [_emulatorView setBackgroundColor: backgroundColor];
    //[_emulatorView setScanLines: scanLines];
    
    [_colorView setColor: backgroundColor];
    
    o = [_parameters objectForKey: kContentFilters];
    if (o)
    {
        [_colorView setWantsLayer: YES];
        [_colorView setContentFilters: (NSArray *)o];
    }

    [self initPTY];
    
}

-(void)windowWillClose:(NSNotification *)notification
{
    [[ChildMonitor monitor] removeController: self];
    [self autorelease];
}

@end



