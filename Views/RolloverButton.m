//
//  RolloverButton.m
//  TwoTerm
//
//  Created by Kelvin Sherlock on 2/13/2018.
//

#import "RolloverButton.h"

@implementation RolloverButton

#if 0
- (void)createTrackingArea
{
    NSTrackingAreaOptions focusTrackingAreaOptions = 0;
    focusTrackingAreaOptions |=  NSTrackingActiveInActiveApp;
    focusTrackingAreaOptions |= NSTrackingMouseEnteredAndExited;
    //focusTrackingAreaOptions |= NSTrackingAssumeInside;
    focusTrackingAreaOptions |= NSTrackingInVisibleRect;
    
    NSTrackingArea *focusTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                                     options:focusTrackingAreaOptions
                                                                       owner:self userInfo:nil];
    [self addTrackingArea:focusTrackingArea];
    [focusTrackingArea release];
}
#endif


- (void) updateTrackingAreas {
    [super updateTrackingAreas];
    if (_trackingArea) {
        [self removeTrackingArea: _trackingArea];
        [_trackingArea release];
    }

    NSTrackingAreaOptions options = 0;
    options |=  NSTrackingActiveInActiveApp;
    options |= NSTrackingMouseEnteredAndExited;
    //options |= NSTrackingAssumeInside;
    options |= NSTrackingInVisibleRect;
    
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                 options:options
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea: _trackingArea];
}


-(void)setImage:(NSImage *)image {
    if (_image != image) {
        [_image release];
        _image = [image retain];
    }
    if (!_rollOver) [super setImage: image];
}

-(void)setRolloverImage: (NSImage *)image {

    if (_rolloverImage != image) {
        [_rolloverImage release];
        _rolloverImage = [image retain];
    }
    if (_rollOver) [super setImage: image];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    //[self createTrackingArea];
    
    [self setImage: [NSImage imageNamed: @"TabClose"]];
    [self setRolloverImage: [NSImage imageNamed: @"TabClose_Rollover"]];
    [[self cell] setHighlightsBy: NSContentsCellMask];
}

-(void)dealloc {
    [_image release];
    [_rolloverImage release];
    [super dealloc];
}

-(void)mouseExited:(NSEvent *)event {

    [[self cell] setImage: _image];
    _rollOver = NO;
    [super mouseExited: event];
}

-(void) mouseEntered:(NSEvent *)event {

    [[self cell] setImage: _rolloverImage];
    _rollOver = YES;
    
    [super mouseEntered: event];
}

@end
