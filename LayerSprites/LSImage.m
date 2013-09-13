//
//  LSImage.m
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

#import "LSImage.h"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This library requires automatic reference counting
#endif


@interface LSImage ()

@property (nonatomic, strong) UIImage *UIImage;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGRect contentsRect;
@property (nonatomic, assign) CGPoint anchorPoint;
@property (nonatomic, assign) CGAffineTransform transform;

@end


@implementation LSImage

+ (LSImage *)imageWithUIImage:(UIImage *)UIImage
                 contentsRect:(CGRect)contentsRect
                  anchorPoint:(CGPoint)anchorPoint
                      rotated:(BOOL)rotated
{
    return [[self alloc] initWithUIImage:UIImage
                            contentsRect:contentsRect
                             anchorPoint:anchorPoint
                                 rotated:rotated];
}

- (LSImage *)initWithUIImage:(UIImage *)UIImage
                contentsRect:(CGRect)contentsRect
                 anchorPoint:(CGPoint)anchorPoint
                     rotated:(BOOL)rotated
{
    if ((self = [super init]))
    {
        _UIImage = UIImage;
        _anchorPoint = anchorPoint;
        _contentsRect = contentsRect;
        _scale = UIImage.scale;
        _size = CGSizeMake(UIImage.size.width * contentsRect.size.width,
                                UIImage.size.height * contentsRect.size.height);
        _transform = rotated? CGAffineTransformMakeRotation(-M_PI_2): CGAffineTransformIdentity;
    }
    return self;
}

- (id)init
{
    return nil;
}

- (CGImageRef)CGImage
{
    return self.UIImage.CGImage;
}

#pragma mark -
#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
    LSImage *copy = [[[self class] allocWithZone:zone] init];
    copy.UIImage = self.UIImage;
    copy.scale = self.scale;
    copy.size = self.size;
    copy.anchorPoint = self.anchorPoint;
    copy.contentsRect = self.contentsRect;
    copy.transform = self.transform;
    return copy;
}

#pragma mark -
#pragma mark Drawing

- (CGRect)rectWhenDrawnAtPoint:(CGPoint)point
{
    //get dimensions
    CGSize size = CGSizeMake(self.size.width, self.size.height);
    CGSize offset = CGSizeMake(self.anchorPoint.x * size.width, self.anchorPoint.y * size.height);
    
    //apply transform
    BOOL rotated = !CGAffineTransformEqualToTransform(self.transform, CGAffineTransformIdentity);
    if (rotated)
    {
        size = CGSizeMake(size.height, size.width);
        offset = CGSizeMake(self.anchorPoint.y * size.width, (1.0 - self.anchorPoint.x) * size.height);
    }
    
    //return rect
    return CGRectMake(point.x - offset.width, point.y - offset.height, size.width, size.height);
}

- (void)drawAtPoint:(CGPoint)point
{
    [self drawInRect:[self rectWhenDrawnAtPoint:point]];
}

- (void)drawInRect:(CGRect)rect
{
    //preserve graphics state
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    //clip and move to drawable area
    CGContextClipToRect(context, rect);
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);
    
    //apply transform
    BOOL rotated = !CGAffineTransformEqualToTransform(self.transform, CGAffineTransformIdentity);
    if (rotated)
    {
        CGContextTranslateCTM(context, rect.size.width/2, rect.size.height/2);
        rect.size = CGSizeMake(rect.size.height, rect.size.width);
        CGContextConcatCTM(context, self.transform);
        CGContextTranslateCTM(context, -rect.size.width/2, -rect.size.height/2);
    }
    
    //create rect
    CGRect drawRect = CGRectZero;
    drawRect.size.width = ceilf(rect.size.width / self.contentsRect.size.width);
    drawRect.size.height = ceilf(rect.size.height / self.contentsRect.size.height);
    drawRect.origin.x = - self.contentsRect.origin.x * drawRect.size.width;
    drawRect.origin.y = - self.contentsRect.origin.y * drawRect.size.height;
    
    //draw image
    [self.UIImage drawInRect:drawRect];
    
    //restore state
    CGContextRestoreGState(context);
}

@end


@implementation CALayer (LSImage)

- (void)setContentsWithLSImage:(LSImage *)image
{
    self.contents = (__bridge id)image.CGImage;
    self.contentsScale = image.scale;
    self.contentsRect = image.contentsRect;
    self.affineTransform = image.transform;
}

- (void)setDimensionsWithLSImage:(LSImage *)image
{
    self.anchorPoint = image.anchorPoint;
    self.bounds = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
}

@end
