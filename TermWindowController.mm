//
//  TermWindowController.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/2/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "ScanLineFilter.h"

#import "TermWindowController.h"
#import "EmulatorView.h"
#import "CurveView.h"
#import "EmulatorWindow.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <atomic>
#include <utility>

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
#include "ColorView.h"

@implementation TermWindowController

@synthesize emulator = _emulator;

+(id)new
{
    return [[self alloc] initWithWindowNibName: @"TermWindow"];
}

-(void)dealloc
{
    [[ChildMonitor monitor] removeController: self];
    
    [_emulator release];
    
    [_popover release];
    [_popoverViewController release];
    
    [_foregroundColor release];
    [_backgroundColor release];

    [super dealloc];
}

-(id)initWithWindow:(NSWindow *)window {
    if ((self = [super initWithWindow: window])) {
        _foregroundColor = [[NSColor greenColor] retain];
        _backgroundColor = [[NSColor blackColor] retain];

        _bloomValue = 0.75;
        _blurValue = 0.0;
        _backlightValue = 0.25;
        _scanlineValue = 0.5;
        _vignetteValue = 0.5;
        _effectsEnabled = YES;
    
    }
    return self;
}

-(void)setParameters: (NSDictionary *)parameters {

    NSColor *o;
    Class klass;

    o = [parameters objectForKey: kForegroundColor];
    o = o ? (NSColor *)o : [NSColor greenColor];
    [self setForegroundColor: o];

    o = [parameters objectForKey: kBackgroundColor];
    o = o ? (NSColor *)o : [NSColor blackColor];
    [self setBackgroundColor: o];

    klass = [parameters objectForKey: kClass];
    if (!klass || ![klass conformsToProtocol: @protocol(Emulator)])
    {
        klass = Nil;
        //klass = [VT52 class];
    }
    
    [self willChangeValueForKey: @"emulator"];
    _emulator = [klass new];
    [self didChangeValueForKey: @"emulator"];

    
#if 0
    [self updateBackgroundColor];
    [self updateForegroundColor];
#endif
}


-(void)initPTY
{
    static std::string username;
    static std::string terminfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // getlogin() sometimes returns crap.
        username = [NSUserName() UTF8String];
        char *cp = getenv("TERMINFO_DIRS");
        if (cp && *cp) {
            terminfo = cp;
            terminfo.push_back(':');
        }
        NSString *s = [[NSBundle mainBundle] resourcePath];
        s = [s stringByAppendingPathComponent: @"terminfo"];
        terminfo += [s UTF8String];
    });
    
    
    pid_t pid;
    int fd;

    struct termios term;
    struct winsize ws = [_emulator defaultSize];
    
    memset(&term, 0, sizeof(term));
    
    term.c_oflag = TTYDEF_OFLAG;
    term.c_lflag = TTYDEF_LFLAG;
    term.c_iflag = TTYDEF_IFLAG;
    term.c_cflag = TTYDEF_CFLAG;
    
    term.c_ispeed = term.c_ospeed = TTYDEF_SPEED;  
    
    memcpy(term.c_cc, ttydefchars, sizeof(ttydefchars));
  
    if ([_emulator respondsToSelector: @selector(initTerm:)])
        [_emulator initTerm: &term];
    
    
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

        s.append("TERMINFO_DIRS=");
        s.append(terminfo.c_str());
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

-(IBAction)resetTerminal: (id)sender {
    [_emulator reset: NO];
}

-(IBAction)hardResetTerminal: (id)sender {
    [_emulator reset: YES];
    [_emulatorView reset];
}
#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowDidLoad
{

    NSWindow *window;
    
    [super windowDidLoad];
    
    
    // resize in 2.0 height increments to prevent jittering the scan lines.
    //[window setResizeIncrements: NSMakeSize(1.0, 2.0)];
    

    window = [self window];

    
    [_emulatorView setEmulator: _emulator];

    [self updateBackgroundColor];
    [self updateForegroundColor];
    
    [_colorView setWantsLayer: YES];
    [_colorView setContentFilters: [self effectsFilter]];

    if ([_emulator respondsToSelector: @selector(characterGenerator)]) {
        id tmp = [_emulator characterGenerator];

        [(EmulatorWindow *)window setTitleCharacterGenerator:tmp];

    }
    
    [self initPTY];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [[ChildMonitor monitor] removeController: self];
    [self autorelease];
}

-(void)windowDidBecomeKey:(NSNotification *)notification {
    [_emulatorView popCursor];
}

-(void)windowDidResignKey:(NSNotification *)notification {
    [_emulatorView pushCursor: Screen::CursorTypeBlock];
}

-(void)popoverWillClose:(NSNotification *)notification {
    [_fg deactivate];
    [_bg deactivate];
    [[NSColorPanel sharedColorPanel] orderOut: self];
}
@end

@implementation TermWindowController (Config)

-(NSColor *)recalcBackgroundColor {
    
    if (_effectsEnabled) {
        return [_backgroundColor blendedColorWithFraction: _backlightValue ofColor: _foregroundColor];
    }
    return _backgroundColor;
}

-(IBAction)filterParameterChanged:(id)sender {
    if (sender == _effectsButton) sender = nil;

    if (sender == nil || sender == _fg) {
        [self updateForegroundColor];
    }
    if (sender == nil || sender == _fg || sender == _bg || sender == _lightenSlider) {
        [self updateBackgroundColor];
    }

    if (sender == nil || sender == _vignetteSlider || sender == _darkenSlider || sender == _bloomSlider) {

        [_colorView setContentFilters: [self effectsFilter]];
    }

#if 0
        CIFilter *filter = [_contentFilters objectAtIndex: 0];
        [filter setValue: @(_vignetteValue) forKey: @"inputIntensity"];
    }

    if (sender == _darkenSlider) {
        CIFilter *filter = [_contentFilters objectAtIndex: 1];
        [filter setValue: @(_scanlineValue) forKey: @"inputDarken"];
    }
    
    if (sender == _bloomSlider) {
        CIFilter *filter = [_contentFilters objectAtIndex: 2];
        [filter setValue: @(_bloomValue) forKey: @"inputIntensity"];
    }
#endif


}

-(NSArray *)effectsFilter {

    if (!_effectsEnabled) return @[];
 
    CIFilter *filter;
    NSMutableArray *filters = [NSMutableArray arrayWithCapacity: 5];
    
    // 1. vignette effect
    filter = [CIFilter filterWithName: @"CIVignette"];
    [filter setDefaults];
    [filter setValue: @(_vignetteValue) forKey: @"inputIntensity"];
    [filter setValue: @(2.0) forKey: @"inputRadius"];
    
    [filters addObject: filter];
    

    // 2. add the scanlines
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: @(_scanlineValue) forKey: @"inputDarken"];
    [filter setValue: @(0.0) forKey: @"inputLighten"];
    [filters addObject: filter];
    
    
    // 3. bloom it...
    filter = [CIFilter filterWithName: @"CIBloom"];
    [filter setDefaults];
    [filter setValue: @2.0 forKey: @"inputRadius"];
    [filter setValue: @(_bloomValue) forKey: @"inputIntensity"];
    
    [filters addObject: filter];
    
#if 0
    //4. blur it a bit...
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: @(_blurValue) forKey: @"inputRadius"];
    
    [filters addObject: filter];
#endif
    
    return filters;
}



#pragma mark - IBActions

-(IBAction)configure: (id)sender {
    
    if (!_popover) {
        NSNib *nib = [[NSNib alloc] initWithNibNamed: @"TermConfig" bundle: nil];
        // n.b. - instantiateWithOwner (10.8+) does not +1 refcount top level objects.
        [nib instantiateWithOwner: self topLevelObjects: nil];
        [nib release];
    }
    if ([_popover isShown]) {
        [_popover close];
    } else {
        [_popover showRelativeToRect: NSZeroRect ofView: _emulatorView preferredEdge: NSRectEdgeMaxX];
    }
}


- (IBAction)foregroundColor:(id)sender {
    [self updateForegroundColor];
}

- (IBAction)backgroundColor:(id)sender {
    
    [self updateBackgroundColor];
}

- (IBAction)swapColors:(id)sender {
    

    [self willChangeValueForKey: @"foregroundColor"];
    [self willChangeValueForKey: @"backgroundColor"];

    std::swap(_foregroundColor, _backgroundColor);

    [self didChangeValueForKey: @"foregroundColor"];
    [self didChangeValueForKey: @"backgroundColor"];

    [self updateBackgroundColor];
    [self updateForegroundColor];
    
    if ([_fg isActive]) {
        [_bg activate: YES];
    } else if ([_bg isActive]) {
        [_fg activate: YES];
    }
}


-(void)updateForegroundColor {
    NSColor *color = _foregroundColor;
    
    NSWindow *window = [self window];
    
    [(EmulatorWindow *)window setTitleTextColor: color];
    
    [_emulatorView setForegroundColor: color];
}

-(void)updateBackgroundColor {
    NSColor *color = [self recalcBackgroundColor];
    NSWindow *window = [self window];
    
    [window setBackgroundColor: color];
    [_colorView setColor: color];
    [_emulatorView setBackgroundColor: color];
}

@end



