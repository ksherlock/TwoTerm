//
//  EmulatorView.m
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include <termios.h>
#include <sys/ioctl.h>

#import "EmulatorView.h"

#import "CharacterGenerator.h"

#import "VT52.h"
#import "VT100.h"


#include "OutputChannel.h"

#import "ScanLineFilter.h"

@implementation EmulatorView

@synthesize fd = _fd;
@synthesize emulator = _emulator;

@synthesize foregroundColor = _foregroundColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize scanLines = _scanLines;


#pragma mark -
#pragma mark properties

-(void)setFd: (int)fd
{
    _fd = fd;
    _screen.setFD(fd);
}

#pragma mark -

-(void)awakeFromNib
{
    _charWidth = 7;
    _charHeight = 16;
    
    _paddingLeft = 8;
    _paddingTop = 8;
    
    
    //_foregroundColor = [[NSColor greenColor] retain];
    //_backgroundColor = [[NSColor blackColor] retain];
    _boldColor = [[NSColor redColor] retain];
    //_foregroundColor  = [[NSColor whiteColor] retain];
    //_backgroundColor = [[NSColor blueColor] retain];
    

    
    _screen.setFD(_fd);
    _screen.setView(self);
    
    _charGen = [[CharacterGenerator generator] retain];
    
    _cursorImg = [[_charGen imageForCharacter: '_'] retain];
    
        
    
    // enable drag+drop for files/urls.
    
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType , nil]];    
    
}

-(void)setBackgroundColor:(NSColor *)color
{
    if (_backgroundColor == color) return;
    
    [_backgroundColor release];
    _backgroundColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

-(void)setForegroundColor:(NSColor *)color
{
    if (_foregroundColor == color) return;
    
    [_foregroundColor release];
    _foregroundColor = [color retain];
    
    [self setNeedsDisplay: YES];
}

-(void)setScanLines:(BOOL)scanLines
{
    if (_scanLines == scanLines) return;
    
    _scanLines = scanLines;
    
    if (_scanLines)
    {
        NSMutableArray *filters;
        CIFilter *filter;
        
        [self setWantsLayer: YES];
        
        filters = [NSMutableArray arrayWithCapacity: 3];
        
        
        
        //add the scanlines (which are vertical and must therfore be rotated
        
        filter = [[ScanLineFilter new] autorelease];
        [filter setValue: [NSNumber numberWithFloat: 0.66] forKey: @"inputOpacity"];
        [filters addObject: filter];
        
        //blur it a bit...
        
        filter = [CIFilter filterWithName: @"CIGaussianBlur"];
        [filter setDefaults];
        [filter setValue: [NSNumber numberWithFloat: 0.33] forKey: @"inputRadius"];
        
        [filters addObject: filter];
        
        [self setContentFilters: filters];   
    }
    else
    {
        [self setContentFilters: nil];
    }
}

-(BOOL)isFlipped
{
    return YES;
}


-(void)viewDidMoveToWindow
{
    [self becomeFirstResponder];

    
    
    _cursorTimer = [[NSTimer scheduledTimerWithTimeInterval: .5 
                                                     target: self 
                                                   selector: @selector(cursorTimer:) 
                                                   userInfo: nil 
                                                    repeats: YES] retain];


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
    //NSRect bounds = [self bounds];

    NSRect screenRect = dirtyRect;

    unsigned x, y;
    

    
    NSColor *currentFront;
    NSColor *currentBack;
    BOOL setFront = YES;
    
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
    
    int minX = floor(screenRect.origin.x / _charWidth);
    int maxX = ceil((screenRect.origin.x + screenRect.size.width) / _charWidth);

    int minY = floor(screenRect.origin.y / _charHeight);
    int maxY = ceil((screenRect.origin.y + screenRect.size.height) / _charHeight);
    
    // x/y are 0-indexed here.

    maxY = std::min(_screen.height() - 1, maxY);
    maxX = std::min(_screen.width() - 1, maxX);
    
    [_backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    [_foregroundColor setFill];

    currentFront = _foregroundColor;
    currentBack = _backgroundColor;
    
    _screen.lock();
    

    for (x = minX; x <= maxX; ++x)
    {
        for (y = minY; y <= maxY; ++y)
        {
            NSRect charRect = NSMakeRect(_paddingLeft + x * _charWidth, _paddingTop + y *_charHeight, _charWidth, _charHeight);
            //NSImage *img;
            CharInfo ci = _screen.getc(x, y);
            unsigned flag = ci.flag;
            uint8_t c = ci.c;
            
            // todo -- check flags to determine fg/bg color, etc.
            // need to draw background individually....


            currentBack = _backgroundColor;
            currentFront = _foregroundColor;
            
            if (flag & Screen::FlagBold)
                currentFront = _boldColor;
            

  
            
            
            //img = [_charGen imageForCharacter: c];
            
            if (flag & Screen::FlagInverse)
            {
  
                // mouse text actually requires mouse text and inverse to be on.
                if (flag & Screen::FlagMouseText)
                {
                    if (c >= '@' && c <= '_') c |= 0x80;
                }
                else
                {
                    std::swap(currentBack, currentFront);
                }
            }
                        
            if (currentBack != _backgroundColor)
            {
                [currentBack setFill];
                NSRectFill(charRect);
                setFront = YES;
            }
            
            if (_foregroundColor != currentFront) setFront = YES;
            if (setFront) [currentFront setFill];

            [_charGen drawCharacter: c 
                            atPoint: NSMakePoint(_paddingLeft + x * _charWidth, _paddingTop + y * _charHeight)];
            

            // strikethrough -- draw a centered line.
            if (flag & Screen::FlagStrike)
            {
            
                NSRectFill(NSMakeRect(_paddingLeft + x * _charWidth, 
                                      _paddingTop + y * _charHeight + floor(_charHeight / 2) - 1, 
                                      _charWidth, 
                                      2));                
            }
            
            // underscore -- draw a bottom line. (eg, ``_'')
            if (flag & Screen::FlagUnderscore)
            {
                NSRectFill(NSMakeRect(_paddingLeft + x * _charWidth, 
                                      _paddingTop + y * _charHeight + _charHeight - 2, 
                                      _charWidth, 
                                      2));
            
            }
            
            
        }
    }
    
    // cursor.
    iPoint cursor = _screen.cursor();
    if (_cursorOn && iRect(minX, minY, maxX - minX, maxY - minY).contains(cursor))
    {
        NSRect charRect = NSMakeRect(_paddingLeft + cursor.x * _charWidth, _paddingTop + cursor.y *_charHeight, _charWidth, _charHeight);

        [_foregroundColor setFill];

        [_cursorImg drawInRect: charRect 
                      fromRect: NSZeroRect operation: NSCompositeCopy 
                      fraction: 1.0 
                respectFlipped: YES 
                         hints: nil];
        
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
    [_cursorImg release];
    
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


-(void)autoTypeText:(NSString *)text
{
    
    NSData *data = [text dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES];

    unsigned length = [data length];
    
    OutputChannel channel(_fd);
    


    if (!length) return;
    
    // bad form to write directly rather than going through Emulator object?
    channel.write([data bytes], length);
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

#if 0
        FILE *debug = fopen("/tmp/debug.txt", "a");
        fwrite(buffer, 1, size, debug);
        fflush(debug);
        fclose(debug);
#endif
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


-(void)resizeTo: (iSize)size animated: (BOOL)animated
{
    NSWindow *window = [self window];
    NSRect bounds = [self bounds];
    NSSize newSize;
    NSRect wframe = [window frame];
    
    
    // TODO -- left/right padding...
    newSize.width = size.width * _charWidth + _paddingLeft * 2;
    newSize.height = size.height * _charHeight + _paddingTop * 2;
    
    // best case -- no change.
    if (NSEqualSizes(newSize,  bounds.size)) return;
    
    
    // ok, change needed.
    
    wframe.origin.y -= (newSize.height - bounds.size.height);
    
    wframe.size.height += newSize.height - bounds.size.height;
    wframe.size.width += newSize.width - bounds.size.width;
    
    _inResizeTo = YES;
    [window setFrame: wframe display: YES animate: animated];
    _inResizeTo = NO;    
}

-(void)resizeTo: (iSize)size
{
    [self resizeTo: size animated: YES];
}



-(void)cursorTimer: (NSTimer *)timer
{
    
    _screen.lock();
    
    _cursorOn = !_cursorOn;

    iRect r(_screen.cursor(), iSize(1,1));
    
    [self invalidateIRect: r];
    
    _screen.unlock();
}


#if 0
-(void)viewWillStartLiveResize
{
    //NSLog(@"%s", sel_getName(_cmd)); 
    
}
#endif
-(void)viewDidEndLiveResize
{
   //NSLog(@"%s", sel_getName(_cmd)); 
    [super viewDidEndLiveResize];
    
    [self setNeedsDisplay: YES];    
}


/*
 * inLiveResize indicates the user is resizing the window -or- the -(void)setWindowFrame: animated: YES.
 * non-live resize indicates zooming or resizeTo w/o animation.
 *
 *
 */
-(void)setFrame:(NSRect)frameRect
{
    //NSLog(@"%s", sel_getName(_cmd)); 

    BOOL inLiveResize = [self inLiveResize];

    [super setFrame: frameRect];

    
    if (inLiveResize && _inResizeTo)
    {
        return;
    }
    
    if (/* inLiveResize */ YES)
    {
        // user is resizing window.
        // or zoom.
        unsigned width = floor((frameRect.size.width - _paddingLeft * 2) / _charWidth);
        unsigned height = floor((frameRect.size.height - _paddingTop * 2) / _charHeight);
        
        _screen.lock();
        _screen.setSize(width, height, false);
        _screen.unlock();
        
        return;
    }
}



#pragma mark -
#pragma mark IBActions


-(IBAction)paste: (id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];

    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];

    if (ok)
    {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSString *string = [objectsToPaste objectAtIndex: 0];
        NSLog(@"%@", objectsToPaste);
        
        [self autoTypeText: string];
        
    }
    
}

-(IBAction)copy: (id)sender
{
}




#pragma mark -
#pragma mark Drag/Drop


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    
    NSPasteboard *pboard;
    pboard = [sender draggingPasteboard];

    NSArray *types = [pboard types];
    
    if ([types containsObject: NSFilenamesPboardType]) return NSDragOperationCopy;
    if ([types containsObject: NSURLPboardType]) return NSDragOperationCopy;
    
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    NSArray *types;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
    
    types = [pboard types];
    

    if ([types containsObject: NSFilenamesPboardType])
    {
        NSArray *array = [pboard propertyListForType: NSFilenamesPboardType];
        NSString *string = (NSString *)[array objectAtIndex: 0];
        
        string = [string stringByReplacingOccurrencesOfString: @"\\" withString: @"\\\\"];
        string = [string stringByReplacingOccurrencesOfString: @" " withString: @"\\ "];
        
        [self autoTypeText: string];
        
        
        //NSArray *array = [pboard propertyListForType: NSFilenamesPboardType];
        //NSLog(@"%@", [array class]);
        //NSLog(@"%@", [pboard propertyListForType: NSFilenamesPboardType]); 
        return YES;
    }
    
    
    
    
    if ([types containsObject: NSURLPboardType])
    {
        NSArray *array = [pboard propertyListForType: NSURLPboardType];
        NSObject *object = (NSObject *)[array objectAtIndex: 0];
        
        if ([object isKindOfClass: [NSString class]])
        {
            [self autoTypeText: (NSString *)object];
            return YES;
        }
        
        if ([object isKindOfClass: [NSURL class]])
        {
            [self autoTypeText: [(NSURL *)object absoluteString]];
            return YES;
        }
        
        // if file://, use the pathname?
        
        
        //NSLog(@"%@", [array class]);
        //NSLog(@"%@", [pboard propertyListForType: NSURLPboardType]); 
    }
    
    return NO;
}



@end



void ViewScreen::setSize(unsigned width, unsigned height)
{
    setSize(width, height, true);
}

void ViewScreen::setSize(unsigned width, unsigned height, bool resizeView)
{    
    // 
    struct winsize ws;
    ws.ws_row = height;
    ws.ws_col = width;
    
    ws.ws_xpixel = 0;
    ws.ws_ypixel = 0;

    Screen::setSize(width, height);

    ioctl(_fd, TIOCSWINSZ, &ws);
    
    if (resizeView)
    {
        [_view resizeTo: iSize(width, height) animated: YES];
    }
}


