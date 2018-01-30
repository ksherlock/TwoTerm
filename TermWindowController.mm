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
    [_emulator release];
    [_emulatorView release];
    [_colorView release];

    [_parameters release];
    [_thread release];
    
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
    _pid = forkpty(&_fd, NULL, &term, &ws);
    
    if (_pid < 0)
    {
        fprintf(stderr, "forkpty failed\n");
        fflush(stderr);
        
        return;
    }
    if (_pid == 0)
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

    [_emulatorView setFd: _fd];
    [self monitor];
}

-(BOOL)read: (int)fd {

    BOOL rv = NO;

    for(;;) {
        
        uint8_t buffer[1024];
        ssize_t size = read(fd, buffer, sizeof(buffer));
        if (size < 0 && errno == EINTR) continue;

        if (size <= 0) break;
        [_emulatorView processData: buffer size: size];
        rv = YES;
    }
    
    return rv;
}

-(int)wait: (pid_t)pid {

    std::atomic_exchange(&_pid, -1);

    int status = 0;
    for(;;) {
        int ok = waitpid(pid, &status, WNOHANG);
        if (ok >= 0) break;
        if (errno == EINTR) continue;
        NSLog(@"waitpid(%d): %s", pid, strerror(errno));
        break;
    }
    return status;
}

-(void)monitor {

    
    int fd = _fd;
    pid_t pid = _pid;
    
    int q = kqueue();
    
    struct kevent events[2] = {};
    
    EV_SET(&events[0], pid, EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT | NOTE_EXITSTATUS, 0, NULL);
    EV_SET(&events[1], fd, EVFILT_READ, EV_ADD | EV_RECEIPT, 0, 0, NULL);
    
    int flags;
    // non-blocking io.
    if (fcntl(_fd, F_GETFL, &flags) < 0) flags = 0;
    fcntl(_fd, F_SETFL, flags | O_NONBLOCK);
    
    kevent(q, events, 2, NULL, 0, NULL);

    [_emulatorView childBegan];

    _thread = [[NSThread alloc] initWithBlock: ^(){
    
        struct kevent events[2] = {};

        bool stop = false;
        int status = 0;

        while (!stop) {
        
            int n = kevent(q, NULL, 0, events, 2, NULL);
            if (n <= 0) {
                NSLog(@"kevent");
                break;
            }

            for (unsigned i = 0; i < n; ++i) {
                const auto &e = events[i];
                unsigned flags = e.flags;
                if (e.filter == EVFILT_READ) {
                    int fd = (int)e.ident;
                    if (flags & EV_EOF) {
                        NSLog(@"EV_EOF");
                    }

                    if (flags & EV_ERROR) {
                        NSLog(@"EV_ERROR");
                    }

                    [self read: fd];
                    continue;
                }

                if (e.filter == EVFILT_PROC) {

                    pid_t pid = (pid_t)e.ident;
                    NSLog(@"Child finished");
                    status = [self wait: pid];
                    stop = true;
                }
            }
        }
        
        if (![_thread isCancelled]) {

            // read any lingering io...
            [self read: fd];

            [_emulatorView childFinished: status];
        }
        close(q);
        close(fd);

        _fd = -1;
        //NSLog(@"Closing fd");
    }];

    [_thread start];
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

    pid_t pid = std::atomic_exchange(&_pid, -1);
    [_thread cancel];

    if (pid > 0) {
        kill(pid, 9);
    }

    [self autorelease];
}

@end



