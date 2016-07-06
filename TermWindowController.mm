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

@synthesize childMonitor = _childMonitor;


+(id)new
{
    return [[self alloc] initWithWindowNibName: @"TermWindow"];
}

-(void)dealloc
{

    [_childMonitor release];
    
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
        
        // should not call exit.
        _exit(-1);
        // child
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
 
    /*
    if (!_childMonitor)
    {
        _childMonitor = [ChildMonitor new];
        [_childMonitor setDelegate: _emulatorView];
    }
    */
}

-(void)monitor {

    int fd = _fd;
    int pid = _pid;

    int flags;
    // non-blocking io.
    if (fcntl(_fd, F_GETFL, &flags) < 0) flags = 0;
    fcntl(_fd, F_SETFL, flags | O_NONBLOCK);
    

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    _wait_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC,
                                              pid, DISPATCH_PROC_EXIT, queue);
    if (_wait_source)
    {
        
        dispatch_source_set_event_handler(_wait_source, ^{
            
            int status = 0;
            waitpid(pid, &status, WNOHANG);
            
            _pid = 0;
            //dispatch_async(dispatch_get_main_queue(), ^(){
            [_emulatorView childFinished: status];
            //});
            
            dispatch_source_cancel(_wait_source);
            dispatch_release(_wait_source);
            _wait_source = nullptr;
        });
            
        dispatch_resume(_wait_source);
    }

    
    _read_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                                          fd, 0, queue);
    if (_read_source)
    {
        // Install the event handler
        dispatch_source_set_event_handler(_read_source, ^{

            static uint8_t sbuffer[1024];
            size_t estimated = dispatch_source_get_data(_read_source) + 1;

            
            uint8_t *buffer = estimated > sizeof(sbuffer) ? (uint8_t *)malloc(estimated) : sbuffer;
            if (buffer)
            {
                ssize_t actual;
                
                for (;;) {
                    actual = read(fd, buffer, (estimated));
                    if (actual < 0) {
                        if (errno == EINTR || errno == EAGAIN) return;
                        NSLog(@"read: %s", strerror(errno));
                        dispatch_source_cancel(_read_source);
                        dispatch_release(_read_source);
                        _read_source = nullptr;
                    }
                    break;
                }

                if (actual > 0) [_emulatorView processData: buffer size: actual];

                if (buffer != sbuffer) free(buffer);

                if (actual == 0 && _pid == 0) {
                    dispatch_source_cancel(_read_source);
                    dispatch_release(_read_source);
                    _read_source = nullptr;
                }
            }
        });

        
        dispatch_source_set_cancel_handler(_read_source, ^{
            _fd = -1;
            [_emulatorView setFd: -1];
            close(fd);
        });
        
        dispatch_resume(_read_source);
    }
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

    [window setBackgroundColor: backgroundColor];

    [_emulatorView setEmulator: _emulator];
    [_emulatorView setForegroundColor: foregroundColor];
    [_emulatorView setBackgroundColor: backgroundColor];
    //[_emulatorView setScanLines: scanLines];
    
    [_curveView setColor: backgroundColor];
    
    o = [_parameters objectForKey: kContentFilters];
    if (o)
    {
        //CALayer *layer;
        [_curveView setWantsLayer: YES];
        
        /*
        CGColorRef color;
        
        color = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
        
        layer = [_curveView layer];
        [layer setCornerRadius: 20.0];
        [layer setBorderWidth: 4.0];
        [layer setBorderColor: color];
        [layer setBackgroundColor: color];
        
        [layer setBackgroundFilters: (NSArray *)o];
        
        CGColorRelease(color);
        */
        [_curveView setContentFilters: (NSArray *)o];
        
        /*
        CALayer *layer;
        CGColorRef color;
        
        color = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);        
        layer = [CALayer layer];
        [layer setFrame: CGRectMake(100, 100, 100, 100)];
        [layer setBackgroundColor: color];
        [layer setBackgroundFilters: nil];
        
        CGColorRelease(color);
        
        [[_curveView layer] addSublayer: layer];
        
        NSLog(@"%@", [layer backgroundFilters]);
        NSLog(@"%@", [[_curveView layer] backgroundFilters]);
        */
    }
    
    /*
    NSShadow *shadow;
    shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowOffset: NSZeroSize];
    [shadow setShadowBlurRadius: 10.0];
    
    [_curveView setShadow: shadow];
    [shadow release];
    */
    
    //[_curveView initScanLines];
    //[_curveView setColor: [NSColor blueColor]];

    [self initPTY];
    
}

-(void)windowWillClose:(NSNotification *)notification
{
    if (_wait_source) {
        dispatch_source_cancel(_wait_source);
        dispatch_release(_wait_source);
    }
    
    if (_read_source) {
        dispatch_source_cancel(_read_source);
        dispatch_release(_read_source);
    }
    
    if (_pid) kill(_pid, 9);

    [self autorelease];
}

@end



