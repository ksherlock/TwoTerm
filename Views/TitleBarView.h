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
    NSTextField *_label;
    NSImage *_rightImage;
    NSImage *_leftImage;
    NSImage *_centerImage;
}

@property (nonatomic, assign) IBOutlet NSTextField *label;
@property (nonatomic, assign) NSString *title;

-(void)fadeIn;
-(void)fadeOut;
@end
