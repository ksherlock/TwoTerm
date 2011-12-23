//
//  EmulatorWindow.h
//  2Term
//
//  Created by Kelvin Sherlock on 11/25/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
@class TitleBarView;

@interface EmulatorWindow : NSWindow
{
    TitleBarView *_titleBarView;
}

@property (nonatomic, retain) IBOutlet TitleBarView *titleBarView;

-(void)adjustTitleBar;


@end
