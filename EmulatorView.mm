//
//  EmulatorView.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>

#import "EmulatorView.h"

#import "CharacterGenerator.h"

#import "VT52.h"

#include "OutputChannel.h"

#import "ScanLineFilter.h"

@implementation EmulatorView

@synthesize fd = _fd;


-(void)awakeFromNib
{
    CIFilter *filter;
    NSMutableArray *filters;
    
    _charWidth = 7;
    _charHeight = 16;
    
    
    
    _foregroundColor = [[NSColor greenColor] retain];
    _backgroundColor = [[NSColor blackColor] retain];
    _boldColor = [[NSColor redColor] retain];
    
    
    [self setWantsLayer: YES];
    
    filters = [NSMutableArray arrayWithCapacity: 3];
    
    
    
    //add the scanlines (which are vertical and must therfore be rotated
    
    filter = [[ScanLineFilter new] autorelease];
    [filter setValue: [NSNumber numberWithFloat: 0.75] forKey: @"inputOpacity"];
    [filters addObject: filter];
    
    //blur it a bit...
    
    filter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue: [NSNumber numberWithFloat: 0.33] forKey: @"inputRadius"];
    
    [filters addObject: filter];
    
    [self setContentFilters: filters];
    
    
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
    unsigned lastFlag = 0;
    
    
    NSColor *currentFront;
    NSColor *currentBack;
    unsigned currentFlag;
    
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

    currentFront = _foregroundColor;
    currentBack = _backgroundColor;
    currentFlag = Screen::FlagNormal;
    
    _screen.lock();
    

    for (x = minX; x <= maxX; ++x)
    {
        for (y = minY; y <= maxY; ++y)
        {
            NSRect charRect = NSMakeRect(_paddingLeft + x * _charWidth, _paddingTop + y *_charHeight, _charWidth, _charHeight);
            NSImage *img;
            CharInfo ci = _screen.getc(x, y);
            
            // todo -- check flags to determine fg/bg color, etc.
            // need to draw background individually....
            if (currentFlag != ci.flag)
            {
                currentFlag = ci.flag;

                currentBack = _backgroundColor;
                currentFront = _foregroundColor;
                if (lastFlag & Screen::FlagBold)
                    currentFront = _boldColor;
                
                if (lastFlag & Screen::FlagInverse)
                {
                    std::swap(currentFront, currentBack);
                }
                
                if (currentFront != _foregroundColor)
                    [currentFront setFill];
            }
            
            img = [_charGen imageForCharacter: ci.c];
            
            if (currentBack != _backgroundColor)
            {
                [currentBack setFill];
                NSRectFill(charRect);
                [currentFront setFill];
            }

            /*
            [img drawAtPoint: NSMakePoint(x * _charWidth, y * _charHeight) 
                    fromRect: NSZeroRect 
                   operation:NSCompositeCopy 
                    fraction: 1.0];
            */
            if (img)
            {
                [img drawInRect: charRect 
                       fromRect: NSZeroRect operation: NSCompositeCopy 
                       fraction: 1.0 
                 respectFlipped: YES 
                          hints: nil];
            }
        }
    }
    _screen.unlock();

    
    //[_scanLine setFill];
    //NSRectFillUsingOperation(screenRect, NSCompositeSourceOver);
    //NSRectFill(screenRect);
    
    
}


-(void)dealloc
{
    close(_fd);
    
    [_foregroundColor release];
    [_backgroundColor release];
    
    [_readerThread release];
    
    [_emulator release];
    
    [super dealloc];
}

-(void)keyDown:(NSEvent *)theEvent
{
    OutputChannel channel(_fd);
    iRect updateRect; // should be nil but whatever...
    
    
    _screen.beginUpdate();
    
    [_emulator keyDown: theEvent screen: &_screen output: &channel];
    
    updateRect = _screen.endUpdate();
    
    [self invalidateIRect: updateRect];
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
        
        [self invalidateIRect: updateRect];
        
        [pool release];
    }
}


-(void)invalidateIRect: (iRect)updateRect
{
    NSRect rect;
    
    if (updateRect.size.width <= 0 || updateRect.size.height <= 0) return;
    
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
    
}


@end
