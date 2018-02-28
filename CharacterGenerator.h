//
//  CharacterGenerator.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/4/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    CGApple80,
    CGApple40,
    CGVT52,
    CGVT100
};

@interface CharacterGenerator : NSObject
{
    NSImage *_image;
    NSImage *_characters[256];
    NSSize _size;
}

+(CharacterGenerator *)generator;
+(CharacterGenerator *)generatorForCharacterSet: (unsigned)characterSet;



@property (nonatomic, readonly) NSSize characterSize;

-(NSImage *)imageForCharacter: (unsigned)character;

-(void)drawCharacter: (unsigned)character atPoint: (NSPoint)point;

@end

