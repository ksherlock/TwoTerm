//
//  RolloverButton.h
//  TwoTerm
//
//  Created by Kelvin Sherlock on 2/13/2018.
//

#import <Cocoa/Cocoa.h>

@interface RolloverButton : NSButton {
    NSImage *_image;
    NSImage *_rolloverImage;
    NSTrackingArea *_trackingArea;
    BOOL _rollOver;
}
@end
