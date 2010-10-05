//
//  EmulatorView.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/3/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "Emulator.h"

#include "iGeometry.h"

#ifdef __cplusplus

#include "Screen.h"

@class EmulatorView;

class ViewScreen: public Screen
{
public:
    
    virtual void setSize(unsigned width, unsigned height);
    
    void setSize(unsigned width, unsigned height, bool resizeView);
    
    void setView(EmulatorView *view) { _view = view; }
    void setFD(int fd) { _fd = fd; }
    
private:
    EmulatorView *_view;
    int _fd;
};


#endif


@class CharacterGenerator;

@interface EmulatorView : NSView {
    
    int _fd;
    
    NSObject<Emulator> *_emulator;
    
    NSThread *_readerThread;
    
    CharacterGenerator *_charGen;
    
    NSColor *_backgroundColor;
    NSColor *_foregroundColor;
    NSColor *_boldColor;
    
    CGFloat _charHeight;
    CGFloat _charWidth;

    CGFloat _paddingTop;
    CGFloat _paddingBottom;
    CGFloat _paddingLeft;
    CGFloat _paddingRight;
    
    NSImage *_cursorImg;
    NSTimer *_cursorTimer;
    BOOL _cursorOn;
        
#ifdef __cplusplus
    
    ViewScreen _screen;
    
#endif
}

@property (nonatomic, assign) int fd;
@property (nonatomic, retain) NSObject<Emulator> *emulator;

//@property (nonatomic, assign) iPoint cursor;


-(void)startBackgroundReader;
-(void)dataAvailable;
-(void)invalidateIRect: (iRect)rect;

-(void)resizeTo: (iSize)size;

-(void)cursorTimer: (NSTimer *)timer;


-(void)autoTypeText: (NSString *)text;

-(IBAction)paste: (id)sender;
-(IBAction)copy: (id)sender;


@end
