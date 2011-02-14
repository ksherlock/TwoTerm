//
//  ExampleView.h
//  2Term
//
//  Created by Kelvin Sherlock on 2/6/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CurveView.h"
@class CharacterGenerator;

@interface ExampleView : CurveView {

    NSColor *_foregroundColor;
    
    CGFloat _blur;
    CGFloat _lighten;
    CGFloat _darken;

    CharacterGenerator *_charGenerator;

}

@property (nonatomic, retain) NSColor *foregroundColor;
@property (nonatomic, assign) CGFloat lighten;
@property (nonatomic, assign) CGFloat darken;
@property (nonatomic, assign) CGFloat blur;


-(void)updateEffects;

@end

