//
//  Emulator.h
//  2Term
//
//  Created by Kelvin Sherlock on 7/7/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include <sys/ttycom.h>
#include <sys/termios.h>

@class NSEvent;
@class NSMenu;

#ifdef __cplusplus
class Screen;
class OutputChannel;


#include <string>

extern "C" unsigned EventCharacters(NSEvent *event, std::u32string &rv);

#else
#define Screen void
#define OutputChannel void
#endif

#import "iGeometry.h"

@class CharacterGenerator;

@interface EmulatorManager : NSObject

+(void)registerClass: (Class)klass;
+(NSMenu *)emulatorMenu;
+(id)emulatorForTag: (unsigned)tag;

@end

@protocol Emulator

@optional
-(void)processCharacter: (uint8_t)c screen: (Screen *)screen output: (OutputChannel *)output;
-(void)processData: (uint8_t *)data length: (size_t)length screen: (Screen *)screen output: (OutputChannel *)output;

-(struct winsize)displaySize;

@required

-(void)keyDown: (NSEvent *)event screen: (Screen *)screen output: (OutputChannel *)output;

-(void)reset: (BOOL)hard;

+(NSString *)name;
-(NSString *)name;

-(const char *)termName;

-(BOOL)resizable;

-(struct winsize)defaultSize;

@optional

-(void)initTerm: (struct termios *)term;
-(CharacterGenerator *)characterGenerator;

@end
