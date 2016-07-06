//
//  TermContentView.h
//  2Term
//
//  Created by Kelvin Sherlock on 11/26/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CurveView.h"

@class TitleBarView;

@interface TermContentView : CurveView
{
    NSTrackingArea *_trackingArea;
    TitleBarView *_titleBar;
}

@property (nonatomic, assign) IBOutlet TitleBarView *titleBar;

@end
