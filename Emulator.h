//
//  Emulator.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/7/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


@class NSEvent;

#ifdef __cplusplus
class Screen;
class OutputChannel;
#else
#define Screen void
#define OutputChannel void
#endif

@protocol Emulator

-(void)processCharacter: (uint8_t)c screen: (Screen *)screen output: (OutputChannel *)output;
-(void)keyDown: (NSEvent *)event screen: (Screen *)screen output: (OutputChannel *)output;
-(void)reset;

-(NSString *)name;

-(const char *)termName;

@end
