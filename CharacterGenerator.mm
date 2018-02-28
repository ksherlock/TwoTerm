//
//  CharacterGenerator.mm
//  2Term
//
//  Created by Kelvin Sherlock on 7/4/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//



#import "CharacterGenerator.h"

@interface CharacterGenerator ()
-(void)loadImageNamed: (NSString *)imageName;
-(id)initWithImageNamed: (NSString *)imageName;
@end

@implementation CharacterGenerator

@synthesize characterSize = _size;

#if 0
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
#endif


+(CharacterGenerator *)generatorForCharacterSet: (unsigned)characterSet {
    
    static CharacterGenerator *singletons[4] = {};
    static NSString *names[] = {
        @"a2-charset-80",
        @"a2-charset-40",
        @"vt52-charset",
        @"vt100-charset",
    };

    constexpr unsigned MaxCharSet = sizeof(names) / sizeof(names[0]);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (unsigned i = 0; i < MaxCharSet; ++i)
            singletons[i] = [[CharacterGenerator alloc] initWithImageNamed: names[i]];
    });
    if (characterSet >= MaxCharSet) return nil;
    return singletons[characterSet];
}


+(id)generator
{
    return [self generatorForCharacterSet: CGApple80];
}


-(id)initWithImageNamed: (NSString *)imageName {
    if ((self = [super init]))
    {
        [self loadImageNamed: imageName];
    }
    
    return self;
}


/*
 * This loads the image then split it up into 256 images.
 *
 * All representations are handled so it retins any @2x artwork.
 *
 */
-(void)loadImageNamed:(NSString *)imageName {


    _image = [[NSImage imageNamed: imageName] retain];
    
    _size = [_image size];
    
    _size.width /= 16;
    _size.height /= 16;

    for (unsigned i = 0; i < sizeof(_characters) / sizeof(_characters[0]); ++i)
        _characters[i] = [[NSImage alloc] initWithSize: _size];
    
    for (NSImageRep *rep in [_image representations]) {

        CGImageRef mask;
        CGImageRef src;
        NSSize size;

        /* src will auto release */
        src = [rep CGImageForProposedRect: NULL context: nil hints: nil];

    
        size.width = CGImageGetWidth(src) / 16;
        size.height = CGImageGetHeight(src) / 16;
    
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
                CGImageRef cgimg = CGImageCreateWithImageInRect(mask, CGRectMake(j * size.width, i * size.height, size.width, size.height));
                
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage: cgimg];
                
                NSImage *nsimg = _characters[i * 16 + j];
                [nsimg addRepresentation: rep];
                [rep release];
                CGImageRelease(cgimg);
            }
            
        }
        
        CGImageRelease(mask);
    }
    
    
    
    
}

-(void)dealloc
{
    [_image release];
    for (auto &o : _characters) [o release];
    
    [super dealloc];
}


-(NSImage *)imageForCharacter: (unsigned)character
{
    if (character >= sizeof(_characters) / sizeof(_characters[0])) return nil;
    
    return _characters[character];
}

-(void)drawCharacter: (unsigned)character atPoint: (NSPoint)point
{

    if (character >= sizeof(_characters) / sizeof(_characters[0])) return;

    NSImage *img = _characters[character];
    
    if (!img) return;
    
    [img drawInRect: (NSRect){point, _size} 
           fromRect: NSZeroRect
          operation: NSCompositeCopy 
           fraction: 1.0 
     respectFlipped: YES 
              hints: nil];


}

@end


