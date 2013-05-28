//
//  LSImageMap.h
//
//  LayerSprites Project
//  Version 1.0.1
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


@interface NSString (Private)

- (BOOL)LS_hasRetinaFileSuffix;
- (NSString *)LS_normalizedPathWithDefaultExtension:(NSString *)extension;

@end


@implementation NSString (Private)

- (BOOL)LS_hasRetinaFileSuffix
{
    SEL pathScaleSelector = NSSelectorFromString(@"scaleFromSuffix");
    if ([self respondsToSelector:pathScaleSelector])
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
    //load image map
    NSString *dataPath = [nameOrPath LS_normalizedPathWithDefaultExtension:@"plist"];
    return [self initWithUIImage:nil path:nameOrPath data:[NSData dataWithContentsOfFile:dataPath]];
}

- (LSImageMap *)initWithUIImage:(UIImage *)image path:(NSString *)path data:(NSData *)data
{
    //calculate scale from path
    NSString *plistPath = [path LS_normalizedPathWithDefaultExtension:@"plist"];
    CGFloat plistScale = [plistPath LS_hasRetinaFileSuffix]? 2.0f: 1.0f;
    CGFloat scale = image.scale / plistScale;
    
    NSPropertyListFormat format = 0;
    NSDictionary *dict = data? [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:NULL]: nil;
    if (dict && [dict isKindOfClass:[NSDictionary class]])
    {
        if (!image)
        {
            //generate default image path
            path = [path stringByDeletingPathExtension];
            
            //get metadata
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
                image = [UIImage imageWithContentsOfFile:[path LS_normalizedPathWithDefaultExtension:@"png"]];
                scale = image.scale / plistScale;
            }
        }
        
        if (image)
        {
            //get texture size
            CGFloat width = CGImageGetWidth(image.CGImage) / scale;
            CGFloat height = CGImageGetHeight(image.CGImage) / scale;
            
            //get frames
            NSDictionary *frames = dict[@"frames"];
            if (frames)
            {
                if ((self = [self init]))
                {
                    for (NSString *name in frames)
                    {
                        NSDictionary *sprite = frames[name];
                        
                        //get contents rect
                        CGRect contentsRect = CGRectFromString(sprite[@"textureRect"] ?: sprite[@"frame"]);
                        contentsRect.origin.x /= width;
                        contentsRect.origin.y /= height;
                        contentsRect.size.width /= width;
                        contentsRect.size.height /= height;
                        
                        //get rotation
                        BOOL rotated = [sprite[@"textureRotated"] ?: sprite[@"rotated"] boolValue];
                        
                        //get offset
                        CGPoint anchorPoint = CGPointMake(0.5f, 0.5f);
                        CGSize offset = CGSizeFromString(sprite[@"spriteOffset"] ?: sprite[@"offset"]);
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
                        
                        //create subimage
                        LSImage *subimage = [LSImage imageWithUIImage:image
                                                         contentsRect:contentsRect
                                                          anchorPoint:anchorPoint
                                                              rotated:rotated];

                        //and image and aliases
                        [self addImage:subimage withName:name];
                        for (NSString *alias in sprite[@"aliases"])
                        {
                            [self addImage:subimage withName:alias];
                        }
                    }
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
    return [self initWithUIImage:image path:nil data:data];
}

- (void)addImage:(LSImage *)image withName:(NSString *)name
{
    self.imagesByName[name] = image;
}

- (NSInteger)imageCount
{
    return [self.imagesByName count];
}

- (NSString *)imageNameAtIndex:(NSInteger)index
{
    return [self.imagesByName allKeys][index];
}

- (LSImage *)imageAtIndex:(NSInteger)index
{
    return [self imageNamed:[self imageNameAtIndex:index]];
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

@end
