//
//  SpriteView.m
//  DrawingDemo
//
//  Created by Nick Lockwood on 20/05/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "SpriteView.h"
#import "LSImageMap.h"
#import <QuartzCore/QuartzCore.h>

#define SPACING CGSizeMake(101,171)

@interface SpriteView ()

@property (nonatomic, strong) LSImageMap *imageMap;

@end


@implementation SpriteView

- (void)awakeFromNib
{
    self.imageMap = [LSImageMap imageMapWithContentsOfFile:@"lostgarden.plist"];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGPoint offset = CGPointZero;
    for (int i = 0; i < [_imageMap imageCount]; i++)
    {
        //draw frame
        UIRectFrame(CGRectMake(offset.x, offset.y, SPACING.width, SPACING.height));
        
        //draw sprite
        LSImage *image = [_imageMap imageAtIndex:i];
        [image drawAtPoint:CGPointMake(offset.x + SPACING.width/2, offset.y + SPACING.height/2)];

        //update offset
        offset.x += SPACING.width;
        if (offset.x > self.bounds.size.width - SPACING.width)
        {
            offset.x = 0;
            offset.y += SPACING.height;
        }
    }
}

@end
