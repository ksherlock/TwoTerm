//
//  CharacterGenerator.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/4/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//



#import "CharacterGenerator.h"

@implementation CharacterGenerator

static CGImageRef PNGImage(NSString *path)
{
    CGImageRef image = NULL;
    CGDataProviderRef provider = NULL;

    if (!path) return NULL;
    
    provider = CGDataProviderCreateWithFilename([path fileSystemRepresentation]);
    if (provider)
    {
        image = CGImageCreateWithPNGDataProvider( provider, NULL, NO, kCGRenderingIntentDefault);
                
        CGDataProviderRelease(provider);
    }
    
    return image;
}


+(id)generator
{
    return [[self new] autorelease];
}

-(id)init
{
    if ((self = [super init]))
    {   
        NSBundle *mainBundle;
        NSString *imagePath;
        
        CGImageRef mask;
        CGImageRef src;
        
        
        mainBundle = [NSBundle mainBundle];
        
        imagePath = [mainBundle pathForResource: @"a2-charset-80" ofType: @"png"];

        
        
        _characters = [[NSMutableArray alloc] initWithCapacity: 256];
        _size = NSMakeSize(7, 16);
        
        
        src = PNGImage(imagePath);
        
        if (src)
        {
            mask = CGImageMaskCreate(CGImageGetWidth(src),
                                     CGImageGetHeight(src),
                                     CGImageGetBitsPerComponent(src),
                                     CGImageGetBitsPerPixel(src),
                                     CGImageGetBytesPerRow(src),
                                     CGImageGetDataProvider(src),
                                     NULL, NO);
            
            
            for (unsigned i = 0; i < 16; ++i)
            {
                for (unsigned j = 0; j < 16; ++j)
                {
                    CGImageRef cgimg = CGImageCreateWithImageInRect(mask, CGRectMake(j * _size.width, i * _size.height, _size.width, _size.height));
                    NSImage *nsimg = [[NSImage alloc] initWithCGImage: cgimg size: _size];
                    [_characters addObject: nsimg];
                    
                    CGImageRelease(cgimg);
                    [nsimg release];
                }
                
            }
            
            CGImageRelease(src);
            CGImageRelease(mask);
        }
    

        
    

    }
    
    return self;
}

-(void)dealloc
{
    if (_image) CGImageRelease(_image);
    [_characters release];
    
    [super dealloc];
}


-(NSImage *)imageForCharacter: (unsigned)character
{
    if (character > [_characters count]) return nil;
    
    return (NSImage *)[_characters objectAtIndex: character];
}

-(void)drawCharacter: (unsigned)character atPoint: (NSPoint)point
{
    NSImage *img = [self imageForCharacter: character];
    
    if (!img) return;
    
    [img drawInRect: (NSRect){point, _size} 
           fromRect: NSZeroRect
          operation: NSCompositeCopy 
           fraction: 1.0 
     respectFlipped: YES 
              hints: nil];


}

@end


