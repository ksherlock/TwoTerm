//
//  EmulatorManager.m
//  2Term
//
//  Created by Kelvin Sherlock on 10/5/2010.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "Emulator.h"
#import <AppKit/AppKit.h>


unsigned EventCharacters(NSEvent *event, std::u32string &rv)
{
    NSEventModifierFlags flags = [event modifierFlags];
    NSString *chars = [event charactersIgnoringModifiers];
    NSUInteger length = [chars length];
    
    rv.reserve(length);
    
    // chars is expected to have 1 character but could have 0 (dead key)
    // or multiple
    for (unsigned i = 0; i < length; ++i)
    {
        unichar c = [chars characterAtIndex: i];
        if (c <= 0x7f)
        {
            if (flags & NSAlphaShiftKeyMask)
            {
                c = flags & NSShiftKeyMask  ? tolower(c) : toupper(c);
            }
            
            if (flags & NSControlKeyMask)
                c = CTRL(c);
        }
        
        rv.push_back(c);
    }
    
    return (unsigned)length;
}



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


// can be called before +load.
+(void)registerClass: (Class)klass
{
    if (klass && [klass conformsToProtocol: @protocol(Emulator)])
    {
        @synchronized (self)
        {
            if (!array)
                array = [NSMutableArray new];

            [array addObject: klass];
            
            [array sortUsingComparator: ^(id lhs, id rhs){
                NSString *a, *b;
                
                a = (NSString *)[lhs name];
                b = (NSString *)[rhs name];
                
                return [a caseInsensitiveCompare: b];
            }];
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
        if (tag && tag <= [array count])
        {
            return [array objectAtIndex: tag - 1];
        }
    }
    return nil;
    
}
@end
