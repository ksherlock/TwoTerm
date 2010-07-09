//
//  EmulatorView.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EmulatorView.h"

#import "CharacterGenerator.h"

#import "VT52.h"

#include "OutputChannel.h"

@implementation EmulatorView

@synthesize fd = _fd;


-(void)awakeFromNib
{
    _charWidth = 7;
    _charHeight = 16;
    
    
    _foregroundColor = [[NSColor greenColor] retain];
    _backgroundColor = [[NSColor blackColor] retain];

    _charGen = [[CharacterGenerator generator] retain];
    

    _emulator = [VT52 new];
}

-(BOOL)isFlipped
{
    return YES;
}


-(void)viewDidMoveToWindow
{
    [self becomeFirstResponder];
}

-(void)viewDidMoveToSuperview
{
    [self becomeFirstResponder];
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];

    NSRect screenRect = dirtyRect;

    unsigned x, y;
    
    screenRect.origin.x -= _paddingLeft;
    screenRect.origin.y -= _paddingTop;
    
    if (screenRect.origin.x < 0)
    {
        screenRect.size.width -= screenRect.origin.x;
        screenRect.origin.x = 0;
    }
    if (screenRect.origin.y < 0)
    {
        screenRect.size.width -= screenRect.origin.y;
        screenRect.origin.y = 0;
    }
    
    unsigned minX = floor(screenRect.origin.x / _charWidth);
    unsigned maxX = ceil((screenRect.origin.x + screenRect.size.width) / _charWidth);

    unsigned minY = floor(screenRect.origin.y / _charHeight);
    unsigned maxY = ceil((screenRect.origin.y + screenRect.size.height) / _charHeight);
    
    // x/y are 0-indexed here.

    maxY = std::min(_screen.height() - 1, maxY);
    maxX = std::min(_screen.width() - 1, maxX);
    
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    [_foregroundColor setFill];

    _screen.lock();
    

    for (x = minX; x <= maxX; ++x)
    {
        for (y = minY; y <= maxY; ++y)
        {
            NSImage *img;
            CharInfo ci = _screen.getc(x, y);
            
            // todo -- check flags to determine fg/bg color, etc.
            
            
            img = [_charGen imageForCharacter: ci.c];
            
            /*
            [img drawAtPoint: NSMakePoint(x * _charWidth, y * _charHeight) 
                    fromRect: NSZeroRect 
                   operation:NSCompositeCopy 
                    fraction: 1.0];
            */
            if (img)
            {
                [img drawInRect: NSMakeRect(_paddingLeft + x * _charWidth, _paddingTop + y *_charHeight, _charWidth, _charHeight) 
                       fromRect: NSZeroRect operation: NSCompositeCopy 
                       fraction: 1.0 
                 respectFlipped: YES 
                          hints: nil];
            }
        }
    }
    
    _screen.unlock();
    
}


-(void)dealloc
{
    close(_fd);
    
    [_readerThread release];
    
    [_emulator release];
    
    [super dealloc];
}

-(void)keyDown:(NSEvent *)theEvent
{
    OutputChannel channel(_fd);
    
    [_emulator keyDown: theEvent screen: &_screen output: &channel];
}

-(void)startBackgroundReader
{
    if (_readerThread) return;
    
    _readerThread = [[NSThread alloc] initWithTarget: self selector: @selector(_readerThread) object: nil];

    [_readerThread start];
}
-(void)_readerThread
{
    // I would prefer to poll(2) but it's broken on os x for ptys.
    
    int fd = _fd;

    
    for(;;)
    {
        int n;
        
        fd_set read_set;
        fd_set error_set;
        
        FD_ZERO(&read_set);
        FD_SET(fd, &read_set);
        FD_ZERO(&error_set);
        FD_SET(fd, &error_set);    
        
        
        n = select(fd + 1, &read_set, NULL, &error_set, NULL);
        
        if (n == 0) continue;
        if (n < 0) break;
        
        if (FD_ISSET(fd, &error_set)) break;
        if (FD_ISSET(fd, &read_set)) [self dataAvailable];
    }
    
}


-(void)dataAvailable
{
    typedef void (*ProcessCharFX)(id, SEL, uint8_t, Screen *, OutputChannel *);
    
    ProcessCharFX fx;
    SEL cmd;
    OutputChannel channel(_fd);
    
    cmd  =  @selector(processCharacter: screen: output:);
    fx = (ProcessCharFX)[_emulator methodForSelector: cmd];
    
    for(;;)
    {
        NSAutoreleasePool *pool;
        iRect updateRect;
        CGRect rect;
        uint8_t buffer[512];
        ssize_t size;
        
        size = read(_fd, buffer, sizeof(buffer));
        
        if (size == 0) break;
        if (size < 0)
        {
            if (errno == EINTR || errno == EAGAIN) continue;
            
            perror("[EmulatorView dataAvailable]");
            break;
        }
        
        
        pool = [NSAutoreleasePool new];
        _screen.beginUpdate();

        
        for (unsigned i = 0; i < size; ++i)
        {
            fx(_emulator,cmd, buffer[i], &_screen, &channel);
        }
        
        updateRect = _screen.endUpdate();    
        
        rect.origin.x = updateRect.origin.x;
        rect.origin.y = updateRect.origin.y;
        rect.size.width = updateRect.size.width;
        rect.size.height = updateRect.size.height;
        
        rect.origin.x *= _charWidth;
        rect.origin.y *= _charHeight;
        rect.size.width *= _charWidth;
        rect.size.height *= _charHeight;

        rect.origin.x += _paddingLeft;
        rect.origin.y += _paddingTop;
        
        [self setNeedsDisplayInRect: rect];
        
        [pool release];
    }
}


@end
