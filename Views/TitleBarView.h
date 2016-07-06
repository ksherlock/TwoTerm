//
//  TitleBarView.h
//  2Term
//
//  Created by Kelvin Sherlock on 11/26/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface TitleBarView : NSView
{
    NSColor *_backgroundColor;
    NSColor *_textColor;
    NSTextField *_label;
    NSImage *_rightImage;
    NSImage *_leftImage;
    NSImage *_centerImage;
    
    BOOL _dark;
}

@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, retain) NSColor *textColor;
@property (nonatomic, retain) IBOutlet NSTextField *label;
@property (nonatomic, retain) NSString *title;

-(void)updateTitle;

-(void)fadeIn;
-(void)fadeOut;
@end
