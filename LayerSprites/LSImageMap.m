//
//  LSImageMap.h
//
//  LayerSprites Project
//  Version 1.2
//
//  Created by Nick Lockwood on 18/05/2013.
//  Copyright 2013 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/LayerSprites
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "LSImageMap.h"
#import <objc/message.h>


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This library requires automatic reference counting
#endif


@implementation NSString (Private)

- (BOOL)LS_hasRetinaFileSuffix
{
    SEL selector = NSSelectorFromString(@"scaleFromSuffix");
    if ([self respondsToSelector:selector])
    {
        return [[self valueForKey:@"scaleFromSuffix"] floatValue] == 2.0f;
    }
    else
    {
        NSString *name = [self stringByDeletingPathExtension];
        if ([name hasSuffix:@"~ipad"]) name = [name substringToIndex:[name length] - 5];
        if ([name hasSuffix:@"~iphone"]) name = [name substringToIndex:[name length] - 7];
        if ([name hasSuffix:@"@2x"]) return YES;
    }
    return NO;
}

- (NSString *)LS_stringByDeletingRetinaSuffix
{
    SEL selector = NSSelectorFromString(@"stringByDeletingRetinaSuffix");
    if ([self respondsToSelector:selector])
    {
        return [self valueForKey:@"stringByDeletingRetinaSuffix"];
    }
    NSString *result = [self stringByDeletingPathExtension];
    if ([result hasSuffix:@"@2x"])
    {
        //TODO: handle ~ipad/~iphone
        result = [result substringToIndex:[result length] - 3];
        return [result stringByAppendingPathExtension:[self pathExtension]];
    }
    return self;
}

- (NSString *)LS_normalizedPathWithDefaultExtension:(NSString *)extension
{
    //extension
    NSString *path = self;
    if (![[self pathExtension] length])
    {
        path = [path stringByAppendingPathExtension:extension];
    }
    else
    {
        extension = [path pathExtension];
    }
    
    //use StandardPaths if available
    SEL normalizedPathSelector = NSSelectorFromString(@"normalizedPathForFile:");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager respondsToSelector:normalizedPathSelector])
    {
        return objc_msgSend(fileManager, normalizedPathSelector, path);
    }
    
    //convert to absolute path
    if (![self isAbsolutePath])
    {
        path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
    }
    
    //check for @2x version
    if ([UIScreen mainScreen].scale == 2.0f)
    {
        NSString *retinaPath = [[[path stringByDeletingPathExtension] stringByAppendingString:@"@2x"] stringByAppendingPathExtension:extension];
        if ([fileManager fileExistsAtPath:retinaPath])
        {
            path = retinaPath;
        }
    }
    
    //check for ~ipad or ~iphone version
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        NSString *iPadPath = [[[path stringByDeletingPathExtension] stringByAppendingString:@"~ipad"] stringByAppendingPathExtension:extension];
        if ([fileManager fileExistsAtPath:iPadPath])
        {
            path = iPadPath;
        }
    }
    else
    {
        NSString *iPhonePath = [[[path stringByDeletingPathExtension] stringByAppendingString:@"~iphone"] stringByAppendingPathExtension:extension];
        if ([fileManager fileExistsAtPath:iPhonePath])
        {
            path = iPhonePath;
        }
    }
    
    //default path
    return [fileManager fileExistsAtPath:path]? path: nil;
}

@end


@interface LSImageMap ()

@property (nonatomic, copy) NSArray *imageNames;
@property (nonatomic, strong) NSMutableDictionary *imagesByName;

@end


@implementation LSImageMap

+ (LSImageMap *)imageMapWithContentsOfFile:(NSString *)nameOrPath
{
    return [[self alloc] initWithContentsOfFile:nameOrPath];
}

+ (LSImageMap *)imageMapWithUIImage:(UIImage *)image data:(NSData *)data
{
    return [[self alloc] initWithUIImage:image data:data];
}

- (LSImageMap *)init
{
    if ((self = [super init]))
    {
        _imagesByName = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (LSImageMap *)initWithContentsOfFile:(NSString *)nameOrPath
{
    //check for xc texture atlas
    NSString *dataPath = [nameOrPath LS_normalizedPathWithDefaultExtension:@"atlasc"];
    if (dataPath && [[dataPath pathExtension] isEqualToString:@"atlasc"])
    {
        if ((self = [self init]))
        {
            //load atlas
            NSString *plistPath = [dataPath stringByAppendingPathComponent:[[[dataPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"]];
            NSDictionary *atlas = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            
            //add sprites
            for (NSDictionary *dict in atlas[@"images"])
            {
                NSString *imagePath = [dataPath stringByAppendingPathComponent:dict[@"path"]];
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                [self addFrames:dict[@"subimages"] withUIImage:image scale:1.0f];
            }
            
            //set sorted image names
            self.imageNames = [[self.imagesByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
        }
        return self;
    }
    else
    {
        //load cocos sprite atlas
        dataPath = [nameOrPath LS_normalizedPathWithDefaultExtension:@"plist"];
        return [self initWithUIImage:nil path:nameOrPath dictionary:[NSDictionary dictionaryWithContentsOfFile:dataPath]];
    }
}

- (LSImageMap *)initWithUIImage:(UIImage *)image path:(NSString *)path dictionary:(NSDictionary *)dict
{
    //calculate scale from path
    NSString *plistPath = [path LS_normalizedPathWithDefaultExtension:@"plist"];
    CGFloat plistScale = [plistPath LS_hasRetinaFileSuffix]? 2.0f: 1.0f;
    CGFloat scale = image.scale / plistScale;
    
    if (dict && [dict isKindOfClass:[NSDictionary class]])
    {
        if (!image)
        {
            //generate default image path
            path = [path stringByDeletingPathExtension];
            
            //check for cocos format metadata
            NSDictionary *metadata = dict[@"metadata"];
            if (metadata)
            {
                //get image file from metadata
                NSString *imageFile = metadata[@"textureFileName"];
                if (!imageFile)
                {
                    NSDictionary *target = metadata[@"target"];
                    if (target)
                    {
                        imageFile = target[@"textureFileName"];
                        NSString *extension = target[@"textureFileExtension"];
                        if (imageFile && extension)
                        {
                            if ([extension hasPrefix:@"."])
                            {
                                imageFile = [imageFile stringByAppendingString:extension];
                            }
                            else
                            {
                                imageFile = [imageFile stringByAppendingPathExtension:extension];
                            }
                        }
                    }
                    if (!imageFile) imageFile = [path lastPathComponent];
                }
                
                //load image
                path = [[path ?: @"" stringByDeletingLastPathComponent] stringByAppendingPathComponent:imageFile];
                image = [UIImage imageWithContentsOfFile:[path LS_normalizedPathWithDefaultExtension:@"png"]];
                
                //set scale
                scale = (CGImageGetWidth(image.CGImage) / CGSizeFromString(metadata[@"size"]).width) ?: (image.scale / plistScale);
            }      
            else
            {
                //derive image path from plist file 
                image = [UIImage imageWithContentsOfFile:[path LS_normalizedPathWithDefaultExtension:@"png"]];
                scale = image.scale / plistScale;
            }
        }
        
        if (image)
        {            
            //get frames
            NSDictionary *frames = dict[@"frames"];
            if (frames)
            {
                if ((self = [self init]))
                {
                    //add sprites
                    [self addFrames:frames withUIImage:image scale:scale];
                    
                    //set sorted image names
                    self.imageNames = [[self.imagesByName allKeys] sortedArrayUsingSelector:@selector(compare:)];
                }
                return self;
            }
            else
            {
                NSLog(@"ImageMap data contains no image frames");
            }
        }
        else
        {
            NSLog(@"Could not locate ImageMap texture file");
        }
    }
    else
    {
        NSLog(@"Unrecognised ImageMap data format");
    }
    
    //not a recognised data format
    return nil;
}

- (LSImageMap *)initWithUIImage:(UIImage *)image data:(NSData *)data
{
    NSPropertyListFormat format = 0;
    NSDictionary *dict = data? [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:NULL]: nil;
    return [self initWithUIImage:image path:nil dictionary:dict];
}

- (void)addFrames:(id)frames withUIImage:(UIImage *)image scale:(CGFloat)scale
{
    //get texture size
    CGFloat width = CGImageGetWidth(image.CGImage) / scale;
    CGFloat height = CGImageGetHeight(image.CGImage) / scale;
    
    for (id item in frames)
    {
        //get sprite name and data
        NSString *name = nil;
        NSDictionary *sprite = nil;
        BOOL cocosFormat = [item isKindOfClass:[NSString class]];
        if (cocosFormat)
        {
            name = item;
            sprite = frames[name];
        }
        else
        {
            sprite = item;
            name = [item[@"name"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if ([name LS_hasRetinaFileSuffix])
            {
                name = [name LS_stringByDeletingRetinaSuffix];
                if (self.imagesByName[name] && [[UIScreen mainScreen] scale] < 2.0f) continue;
            }
            else if (self.imagesByName[name])
            {
                continue;
            }
        }
        
        //get contents rect
        CGRect contentsRect = CGRectFromString(sprite[@"textureRect"] ?: sprite[@"frame"]);
        contentsRect.origin.x /= width;
        contentsRect.origin.y /= height;
        contentsRect.size.width /= width;
        contentsRect.size.height /= height;
        
        //get rotation
        BOOL rotated = [sprite[@"textureRotated"] ?: sprite[@"rotated"] boolValue];
        if (rotated && sprite[@"frame"])
        {
            contentsRect.size = CGSizeMake(contentsRect.size.height * height / width,
                                           contentsRect.size.width * width / height);
        }
        
        //get offset
        CGPoint anchorPoint = CGPointMake(0.5f, 0.5f);
        CGSize offset = CGSizeFromString(sprite[@"spriteOffset"] ?: sprite[@"offset"]);
        if (cocosFormat)
        {
            if (!CGSizeEqualToSize(offset, CGSizeZero))
            {
                if (rotated)
                {
                    anchorPoint.x -= offset.height / (contentsRect.size.width * width);
                    anchorPoint.y += offset.width / (contentsRect.size.height * height);
                }
                else
                {
                    anchorPoint.x -= offset.width / (contentsRect.size.width * width);
                    anchorPoint.y += offset.height / (contentsRect.size.height * height);
                }
            }
        }
        else
        {
            CGSize sourceSize = CGSizeFromString(sprite[@"spriteSourceSize"]);
            if (rotated)
            {
                anchorPoint.x -= (offset.height + (contentsRect.size.width * width / 2.0) - (sourceSize.height / 2.0)) / (contentsRect.size.width * width);
                anchorPoint.y -= (offset.width + (contentsRect.size.height * height / 2.0) - (sourceSize.width / 2.0)) / (contentsRect.size.height * height);
            }
            else
            {
                anchorPoint.x += (offset.width + (contentsRect.size.width * width / 2.0) - (sourceSize.width / 2.0)) / (contentsRect.size.width * width);
                anchorPoint.y += (offset.height + (contentsRect.size.height * height / 2.0) - (sourceSize.height / 2.0)) / (contentsRect.size.height * height);
            }
        }
        
        //create subimage
        LSImage *subimage = [LSImage imageWithUIImage:image
                                         contentsRect:contentsRect
                                          anchorPoint:anchorPoint
                                              rotated:rotated];
        
        //and image and aliases
        self.imagesByName[name] = subimage;
        for (NSString *alias in sprite[@"aliases"])
        {
            self.imagesByName[alias] = subimage;
        }
    }
}

- (NSInteger)imageCount
{
    return [self.imagesByName count];
}

- (NSString *)imageNameAtIndex:(NSInteger)index
{
    return self.imageNames[index];
}

- (LSImage *)imageAtIndex:(NSInteger)index
{
    return self.imagesByName[self.imageNames[index]];
}

- (LSImage *)imageNamed:(NSString *)name
{
    LSImage *image = self.imagesByName[name];
    if (!image)
    {
        return self.imagesByName[[name stringByAppendingPathExtension:@"png"]];
    }
    return image;
}

- (LSImage *)objectAtIndexedSubscript:(NSInteger)index
{
    return [self imageAtIndex:index];
}

- (LSImage *)objectForKeyedSubscript:(NSString *)name
{
    return [self imageNamed:name];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [self.imageNames countByEnumeratingWithState:state objects:buffer count:len];
}

@end
