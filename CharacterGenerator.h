//
//  CharacterGenerator.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/4/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CharacterGenerator : NSObject {

    unsigned _base;
    NSArray *_characters;
}

+(CharacterGenerator *)generator;

-(NSImage *)imageForCharacter: (unsigned)character;

@end
