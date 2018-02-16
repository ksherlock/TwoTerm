//
//  CharacterGenerator.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/4/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CharacterGenerator : NSObject
{
    NSImage *_image;
    NSImage *_characters[256];
    NSSize _size;
}

+(CharacterGenerator *)generator;

@property (nonatomic, readonly) NSSize characterSize;

-(NSImage *)imageForCharacter: (unsigned)character;

-(void)drawCharacter: (unsigned)character atPoint: (NSPoint)point;

@end

