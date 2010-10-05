//
//  EmulatorManager.m
//  2Term
//
//  Created by Kelvin Sherlock on 10/5/2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "Emulator.h"
#import <AppKit/AppKit.h>

@implementation EmulatorManager

static NSMutableArray *array = nil;

+(id)alloc
{ 
    return nil; 
}
+(id)new
{
    return nil;
}

-(id)init
{
    [self release]; 
    return nil; 
}

+(void)load
{
    array = [NSMutableArray new];
}

+(void)registerClass: (Class)klass
{
    if (klass && [klass conformsToProtocol: @protocol(Emulator)])
    {
        @synchronized (self)
        {
            [array addObject: klass];
        }
    }
    
}

+(NSMenu *)emulatorMenu
{
    NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"Terminal Type"] autorelease];
    
    @synchronized (self)
    {
        unsigned index = 0;
        for (Class klass in array)
        {
            NSMenuItem *item = [[NSMenuItem new] autorelease];
            
            [item setTitle: [klass name]];
            [item setTag: ++index];
            [menu addItem: item];
        }
    }
    
    return menu;
}

+(id)emulatorForTag: (unsigned)tag
{
    @synchronized(self) 
    {
        if (tag && tag < [array count])
        {
            return [array objectAtIndex: tag - 1];
        }
    }
    return nil;
    
}
@end
