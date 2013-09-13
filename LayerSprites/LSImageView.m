//
//  LSImageView.m
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

#import "LSImageView.h"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This library requires automatic reference counting
#endif


@interface LSImageView ()

@property (nonatomic, strong) CALayer *spriteLayer;

@end


@implementation LSImageView

- (void)LS_setUp
{
    self.spriteLayer = [CALayer layer];
    self.spriteLayer.actions = @{@"contents": [NSNull null],
                                 @"contentsRect": [NSNull null],
                                 @"contentsScale": [NSNull null],
                                 @"bounds": [NSNull null],
                                 @"position": [NSNull null],
                                 @"anchorPoint": [NSNull null],
                                 @"transform": [NSNull null]};
    [self.layer addSublayer:self.spriteLayer];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.contentMode = UIViewContentModeCenter;
        [self LS_setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self LS_setUp];
    }
    return self;
}

- (instancetype)initWithImage:(LSImage *)image
{
    CGRect frame = [image rectWhenDrawnAtPoint:CGPointZero];
    frame.size.width = MAX(-frame.origin.x, frame.size.width + frame.origin.x) * 2.0f;
    frame.size.height = MAX(-frame.origin.y, frame.size.height + frame.origin.y) * 2.0f;
    frame.origin = CGPointZero;
    
    if (self = [self initWithFrame:frame])
    {
        self.image = image;
    }
    return self;
}

- (void)setImage:(LSImage *)image
{
    _image = image;
    [self.spriteLayer setContentsWithLSImage:image];
    [self setNeedsLayout];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    super.contentMode = contentMode;
    [self setNeedsLayout];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    switch (self.contentMode)
    {
        case UIViewContentModeScaleToFill:
        {
            return self.image.size;
        }
        case UIViewContentModeCenter:
        default:
        {
            CGRect frame = [self.image rectWhenDrawnAtPoint:CGPointZero];
            frame.size.width = MAX(-frame.origin.x, frame.size.width + frame.origin.x) * 2.0f;
            frame.size.height = MAX(-frame.origin.y, frame.size.height + frame.origin.y) * 2.0f;
            return frame.size;
        }
        //TODO: other content modes
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    switch (self.contentMode)
    {
        case UIViewContentModeScaleToFill:
        {
            self.spriteLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
            self.spriteLayer.frame = self.bounds;
            break;
        }
        case UIViewContentModeCenter:
        default:
        {
            [self.spriteLayer setDimensionsWithLSImage:self.image];
            self.spriteLayer.position = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
            break;
        }
        //TODO: other content modes
    }
}

@end
