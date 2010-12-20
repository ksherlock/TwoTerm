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

#import "VT52.h"
#import "PTSE.h"

#import "Defaults.h"


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
@synthesize emulatorView = _emulatorView;
@synthesize curveView = _curveView;

@synthesize parameters = _parameters;



+(id)new
{
    return [[self alloc] initWithWindowNibName: @"TermWindow"];
}

-(void)dealloc
{    
    [_emulator release];
    [_emulatorView release];
    [_curveView release];

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
    int pid;
    int fd;
    struct termios term;
    struct winsize ws = [_emulator defaultSize];
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
        fprintf(stderr, "forkpty failed\n");
        fflush(stderr);
        
        return;
    }
    if (pid == 0)
    {
        
        std::vector<const char *> environ;
        std::string s;
        
            
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
    
    [_emulatorView resizeTo: iSize(ws.ws_col, ws.ws_row)];

    if (![_emulator resizable])
    {
        
        NSWindow *window = [self window];
        NSUInteger mask = [window styleMask];
        
        
        [window setShowsResizeIndicator: NO];
        
        [window setStyleMask: mask & ~NSResizableWindowMask];
    }
    
    _child = pid;
    
    [_emulatorView setFd: fd];
    [_emulatorView startBackgroundReader];
}


#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowDidLoad
{
    
    BOOL scanLines;
    NSColor *foregroundColor;
    NSColor *backgroundColor;
    Class klass;
    id o;
    
    [super windowDidLoad];
    
    klass = [_parameters objectForKey: kClass];
    if (!klass || ![klass conformsToProtocol: @protocol(Emulator)])
    {
        klass = [VT52 class];
    }
    
    o = [_parameters objectForKey: kScanLines];
    scanLines = o ? [(NSNumber *)o boolValue] : YES;
    
    o = [_parameters objectForKey: kForegroundColor];
    foregroundColor = o ? (NSColor *)o : [NSColor greenColor];
    
    o = [_parameters objectForKey: kBackgroundColor];
    backgroundColor = o ? (NSColor *)o : [NSColor blackColor];
    
    
    [self willChangeValueForKey: @"emulator"];
    _emulator = [klass new];
    [self didChangeValueForKey: @"emulator"];


    [_emulatorView setEmulator: _emulator];
    [_emulatorView setForegroundColor: foregroundColor];
    [_emulatorView setBackgroundColor: backgroundColor];
    [_emulatorView setScanLines: scanLines];
    
    
    //[_curveView initScanLines];
    //[_curveView setColor: [NSColor blueColor]];
    
    [self initPTY];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [self autorelease];
}

@end
