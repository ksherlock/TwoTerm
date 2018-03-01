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

//#import "VT52.h"
//#import "VT100.h"


#include "OutputChannel.h"

#import "ScanLineFilter.h"


@implementation EmulatorView (Cursor)

-(void)startCursorTimer
{
    // timers must be added/removed from the same thread.
    
    if (_cursorTimer) return;
    
    if ([NSThread isMainThread])
    {

        _cursorOn = NO;
        _cursorTimer = [[NSTimer alloc] initWithFireDate: [NSDate date] 
                                                interval: 0.5
                                                  target: self
                                                selector: @selector(cursorTimer:) 
                                                userInfo: nil 
                                                 repeats: YES ];
        [[NSRunLoop currentRunLoop] addTimer: _cursorTimer forMode: NSDefaultRunLoopMode];
        
    }
    else
    {
        [self performSelectorOnMainThread: _cmd withObject: nil waitUntilDone: NO];
    }
}

-(void)stopCursorTimer
{
    if ([NSThread isMainThread])
    {
        [_cursorTimer invalidate];
        [_cursorTimer release];
        _cursorTimer = nil;

        _cursorOn = YES;
        iRect r(_screen.cursor(), iSize(1,1));
        [self invalidateIRect: r];
    }
    else
    {
        [self performSelectorOnMainThread: _cmd withObject: nil waitUntilDone: NO];
    }
}


-(void)cursorTimer: (NSTimer *)timer
{
    if (_cursorType == Screen::CursorTypeNone) return;

    _screen.lock();
    
    _cursorOn = !_cursorOn;
    
    iRect r(_screen.cursor(), iSize(1,1));
    
    [self invalidateIRect: r];
    
    _screen.unlock();
}

-(void)setCursorType: (unsigned)cursorType
{
    if (_cursorType == cursorType) return;

    _cursorType = cursorType;
    iRect r(_screen.cursor(), iSize(1,1));
    [self invalidateIRect: r];
}
-(unsigned)cursorType
{
    return _cursorType;
}

-(void)pushCursor:(unsigned)type {
    if (_fd < 0) return;

    _cursorStack.push_back(_cursorType);
    [self setCursorType: type];
    [self stopCursorTimer];
}

-(void)popCursor {
    if (_fd < 0) return;

    if (!_cursorStack.empty()) {
        [self setCursorType: _cursorStack.back()];
        _cursorStack.pop_back();
        if (_cursorStack.empty()) [self startCursorTimer];
    }
}

@end

@implementation EmulatorView

@synthesize fd = _fd;
//@synthesize cursorType = _cursorType;

@synthesize emulator = _emulator;

@synthesize foregroundColor = _foregroundColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize scanLines = _scanLines;
//@synthesize cursorType = _cursorType;
@dynamic cursorType;

#pragma mark -
#pragma mark properties

-(int)fd {
    return _fd;
}

-(void)setFd: (int)fd
{
    _fd = fd;
    _screen.setFD(fd);
}

-(void)setCharacterGenerator: (CharacterGenerator *)generator {
    if (generator != _charGen) {
        [_charGen release];
        _charGen = [generator retain];
        NSSize size = [_charGen characterSize];
        _charWidth = size.width;
        _charHeight = size.height;
        
    }
}

-(void)setEmulator:(NSObject<Emulator> *)emulator {
    if (_emulator == emulator) return;
    [_emulator release];
    _emulator = [emulator retain];
    if ([emulator respondsToSelector: @selector(characterGenerator)]) {
        id cg = [emulator characterGenerator];
        if (cg) [self setCharacterGenerator: cg];
    }
        
}

#pragma mark -

-(void)awakeFromNib
{
    _charWidth = 7;
    _charHeight = 16;
    
    _paddingLeft = 8;
    _paddingTop = 8;
    _paddingBottom = 8;
    _fd = -1;
    
    //_foregroundColor = [[NSColor greenColor] retain];
    //_backgroundColor = [[NSColor blackColor] retain];
    _boldColor = [[NSColor redColor] retain];
    //_foregroundColor  = [[NSColor whiteColor] retain];
    //_backgroundColor = [[NSColor blueColor] retain];
    

    
    _screen.setFD(_fd);
    _screen.setView(self);
    
    [self setCharacterGenerator: [CharacterGenerator generatorForCharacterSet: CGApple80]];
    
    _cursorType = Screen::CursorTypeUnderscore;

    _cursors[Screen::CursorTypeNone] = nil;
    _cursors[Screen::CursorTypeUnderscore] = [[_charGen imageForCharacter: '_'] retain];
    _cursors[Screen::CursorTypePipe] = [[_charGen imageForCharacter: '|'] retain];
    _cursors[Screen::CursorTypeBlock] = [[_charGen imageForCharacter: 0x80] retain];
    _cursors[Screen::CursorTypeCrossHatch] = [[_charGen imageForCharacter: 0x7f] retain];
    
    
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

-(BOOL)isFlipped
{
    return YES;
}

-(BOOL)isOpaque {
    return NO;
}

-(void)viewDidMoveToWindow
{
    [self becomeFirstResponder];

    
    [self startCursorTimer];
    
}

-(void)viewDidMoveToSuperview
{
    [self becomeFirstResponder];
}

-(BOOL)canBecomeKeyView {
    return YES;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(BOOL)resignFirstResponder {
    return [super resignFirstResponder];
}

-(void)drawRect:(NSRect)dirtyRect
{
    //NSLog(@"drawRect:");
    
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

    //currentFront = _foregroundColor;
    //currentBack = _backgroundColor;
    
    _screen.lock();
    

    for (x = minX; x <= maxX; ++x)
    {
        for (y = minY; y <= maxY; ++y)
        {
            NSRect charRect = NSMakeRect(_paddingLeft + x * _charWidth, _paddingTop + y *_charHeight, _charWidth, _charHeight);
            //NSImage *img;
            char_info ci = _screen.getc(iPoint(x, y));
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
            
            
            if (_cursorType == Screen::CursorTypeBlock && _cursorOn && _screen.cursor() == iPoint(x, y)) {

                std::swap(currentBack, currentFront);

            }
            
            if (currentBack != _backgroundColor)
            {
                [currentBack setFill];
                NSRectFill(charRect);
                setFront = YES;
            }
            
            if (_foregroundColor != currentFront) setFront = YES;
            if (setFront) [currentFront setFill];

            // need to apply the scanline filter here.
            
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
    if (_cursorOn && iRect(minX, minY, maxX - minX, maxY - minY).contains(cursor) && _cursorType != Screen::CursorTypeBlock)
    {
        NSRect charRect = NSMakeRect(_paddingLeft + cursor.x * _charWidth, _paddingTop + cursor.y *_charHeight, _charWidth, _charHeight);


        [_foregroundColor setFill];

        NSImage *img = _cursors[_cursorType];
        NSCompositingOperation op = NSCompositingOperationCopy;
        //if (_cursorType == Screen::CursorTypeBlock) op = NSCompositingOperationXOR;
        [img drawInRect: charRect
               fromRect: NSZeroRect
              operation: op
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
    [_foregroundColor release];
    [_backgroundColor release];
    
    
    [_emulator release];
    //[_cursorImg release];
    for (int i = 0; i < 4; ++i) [_cursors[i] release];
    [super dealloc];
}

-(void)keyDown:(NSEvent *)theEvent
{
    //NSLog(@"keyDown:");
    if (_fd < 0) return;

    OutputChannel channel(_fd);
    iRect updateRect; // should be nil but whatever...
    
    // todo -- after _fd closes, need to block further activity.
    
    
    [NSCursor setHiddenUntilMouseMoves: YES];
    
    _screen.beginUpdate();
    
    [_emulator keyDown: theEvent screen: &_screen output: &channel];
    
    updateRect = _screen.endUpdate();
    
    [self invalidateIRect: updateRect];
}


-(void)autoTypeText:(NSString *)text
{
    
    if (_fd < 0) return;

    NSData *data = [text dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: YES];

    NSUInteger length = [data length];
    
    OutputChannel channel(_fd);
    


    if (!length) return;
    
    // bad form to write directly rather than going through Emulator object?
    channel.write([data bytes], length);
}

-(void)childBegan {
    //[self startCursorTimer];
}

-(void)childFinished:(int)status {
    
    // called from other thread.
    
    //NSLog(@"[process complete]");
    
    _fd = -1;
    dispatch_async(dispatch_get_main_queue(), ^(){
        
        iRect updateRect;
        
        [self setCursorType: Screen::CursorTypeCrossHatch];
        [self stopCursorTimer];
        //_screen.setCursorType(Screen::CursorTypeNone);
        
#if 0
        _screen.beginUpdate();
        
        _screen.setX(0);
        _screen.incrementY();
        
        for (const char *cp = "[Process completed]"; *cp; ++cp)
        {
            _screen.putc(*cp);
        }
        
        updateRect = _screen.endUpdate();
        
        
        [self invalidateIRect: updateRect];
#endif
        
        //[_emulator writeLine: @"[Process completed]"];
        
    });
    
    
    
}

-(IBAction)clearDebugData:(id)sender {
    _debug_buffer.clear();
}


-(IBAction)copyDebugData:(id)sender {
    
    /* copy _debug_data to clipboard */
    
    std::vector<uint8_t> bytes = _debug_buffer.read();
    
    std::string ascii;
    std::string hex;
    ascii.reserve(bytes.size());
    hex.reserve(bytes.size()*3);
    
    std::transform(bytes.begin(), bytes.end(), std::back_inserter(ascii), [](uint8_t c){
        if (isascii(c) && isprint(c)) return (char)c;
        return (char)'.';
    });
    
    for (uint8_t c : bytes) {
        constexpr const static char hh[] = "0123456789abcdef";
        hex.push_back(hh[c >> 4]);
        hex.push_back(hh[c & 0x0f]);
        hex.push_back(' ');
    }
    
    
    std::string rv;
    int offset = 0;
    while (offset < bytes.size()) {
        size_t max = bytes.size() - offset;
        if (max > 16) max = 16;
        
        rv.append(hex.data() + offset * 3, max * 3);
        if (max < 16) rv.append((16 - max) * 3, ' ');
        rv.push_back(' ');
        rv.append(ascii.data() + offset, max);
        rv.push_back('\n');
        
        offset += max;
    }

    NSPasteboard *pb;
    pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setData: [NSData dataWithBytes: rv.data() length: rv.length()] forType: NSStringPboardType];
}

-(void)processData: (uint8_t *)buffer size:(size_t)size {

    typedef void (*ProcessCharFX)(id, SEL, uint8_t, Screen *, OutputChannel *);
    
    OutputChannel channel(_fd);
    iRect updateRect;

    
    _debug_buffer.write(buffer, size);
    
    if ([_emulator respondsToSelector: @selector(processData:length:screen:output:)]) {
        
        @autoreleasepool {
            
            _screen.beginUpdate();
            [_emulator processData: buffer length: size screen: &_screen output: &channel];
            updateRect = _screen.endUpdate();
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                
                [self invalidateIRect: updateRect];
                
            });
        
        }
        return;
    }
    
    @autoreleasepool {
        
        SEL cmd  =  @selector(processCharacter: screen: output:);
        ProcessCharFX fx = (ProcessCharFX)[_emulator methodForSelector: cmd];
        
        _screen.beginUpdate();
        
        
        for (unsigned i = 0; i < size; ++i)
        {
            fx(_emulator, cmd, buffer[i], &_screen, &channel);
        }
        
        updateRect = _screen.endUpdate();
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            
            [self invalidateIRect: updateRect];
            
        });

    }
}



// should be done in the main thread.
-(void)invalidateIRect: (iRect)updateRect
{
    //NSLog(@"invalidateIRect");
    
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
    
    dispatch_async(dispatch_get_main_queue(), ^(){

        [self setNeedsDisplayInRect: rect];
        
        //[self display];
        
    });
    
    //[self setNeedsDisplayInRect: rect];
    //[self display];
     
    
}


-(void)resizeTo: (iSize)size animated: (BOOL)animated
{
    NSWindow *window = [self window];
    NSRect bounds = [self bounds];
    NSSize newSize;
    NSRect wframe = [window frame];
    
    
    // TODO -- left/right padding...
    newSize.width = size.width * _charWidth + _paddingLeft * 2;
    newSize.height = size.height * _charHeight + _paddingTop + _paddingBottom;
    
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
        unsigned height = floor((frameRect.size.height - _paddingTop - _paddingBottom) / _charHeight);
        
        _screen.lock();
        _screen.setSize(width, height, false);
        _screen.unlock();
        
        return;
    }
}



#pragma mark -
#pragma mark IBActions

-(BOOL)validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem {
    
    SEL cmd = [anItem action];
    if (cmd == @selector(paste:)) {
        return _fd >= 0;
    }
    if (cmd == @selector(copy:)) return NO;
    if (cmd == @selector(copyDebugData:)) return YES;
    if (cmd == @selector(clearDebugData:)) return YES;
    
    return NO;
    //return [super validateUserInterfaceItem: anItem];
}
//-(BOOL)validateUserInterfaceItem:
-(IBAction)paste: (id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];

    if (_fd < 0) return;

    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];

    if (ok)
    {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSString *string = [objectsToPaste objectAtIndex: 0];
        //NSLog(@"%@", objectsToPaste);
        
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
 
    
    if (_fd < 0) return NO;

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


-(void)reset {
    _screen.eraseScreen();
    _screen.setCursor(iPoint(0,0));
    _cursorOn = YES;
    [self setNeedsDisplay: YES];
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

void ViewScreen::setCursorType(CursorType cursorType)
{
    Screen::setCursorType(cursorType);
    [_view setCursorType: cursorType];
}



