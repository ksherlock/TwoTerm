//
//  EmulatorView.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EmulatorView.h"

#import "CharacterGenerator.h"

@implementation EmulatorView

@synthesize fd = _fd;
@synthesize cursorPosition = _cursor;


-(void)awakeFromNib
{
    _charWidth = 7;
    _charHeight = 16;
    
    _height = 24;
    _width = 80;
    
    _foregroundColor = [[NSColor greenColor] retain];
    _backgroundColor = [[NSColor blackColor] retain];

    _charGen = [[CharacterGenerator generator] retain];
    
    _lock = [NSLock new];

    
    std::memset(_screen, 0, sizeof(_screen));
    
    
    _cursor = CursorPosition(0, 0);
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


    unsigned x, y;
    
    unsigned minX = floor(dirtyRect.origin.x / _charWidth);
    unsigned maxX = ceil((dirtyRect.origin.x + dirtyRect.size.width) / _charWidth);

    unsigned minY = floor(dirtyRect.origin.y / _charHeight);
    unsigned maxY = ceil((dirtyRect.origin.y + dirtyRect.size.height) / _charHeight);
    
    // x/y are 0-indexed here.

    maxY = std::min(_height - 1, maxY);
    maxX = std::min(_width - 1, maxX);
    
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    [_foregroundColor setFill];

    

    
    [_lock lock];

    for (x = minX; x <= maxX; ++x)
    {
        for (y = minY; y <= maxY; ++y)
        {
            NSImage *img;
            CharInfo ci = _screen[y][x];
            
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
                [img drawInRect: NSMakeRect(x * _charWidth, y *_charHeight, _charWidth, _charHeight) 
                       fromRect: NSZeroRect operation: NSCompositeCopy 
                       fraction: 1.0 
                 respectFlipped: YES 
                          hints: nil];
            }
        }
    }
    
    [_lock unlock];

}


-(void)dealloc
{
    [_readerThread release];
    [_lock release];
    
    [super dealloc];
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


-(void)dataAvailable { }


@end
