//
//  ViewController.m
//  DrawingDemo
//
//  Created by Nick Lockwood on 20/05/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "ViewController.h"
#import "LSImageMap.h"
#import <QuartzCore/QuartzCore.h>

#define SPACING CGSizeMake(101,171)

@interface ViewController ()

@property (nonatomic, strong) LSImageMap *imageMap;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageMap = [LSImageMap imageMapWithContentsOfFile:@"lostgarden.plist"];
    
    for (int i = 0; i < [_imageMap imageCount]; i++)
    {
        //get sprite
        LSImage *image = [_imageMap imageAtIndex:i];
        
        //create border layer
        CALayer *border = [CALayer layer];
        border.bounds = CGRectMake(0, 0, SPACING.width, SPACING.height);
        border.borderColor = [UIColor blackColor].CGColor;
        border.borderWidth = 1;
        [self.view.layer addSublayer:border];
        
        //create sprite layer
        CALayer *sprite = [CALayer layer];
        [sprite setContentsWithLSImage:image];
        [sprite setDimensionsWithLSImage:image];
        sprite.position = CGPointMake(SPACING.width / 2, SPACING.height / 2);
        [border addSublayer:sprite];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    //update layer positions
    CGPoint offset = CGPointZero;
    for (int i = 0; i < [self.view.layer.sublayers count]; i++)
    {
        //get layer
        CALayer *layer = self.view.layer.sublayers[i];
        layer.position = CGPointMake(offset.x + SPACING.width/2, offset.y + SPACING.height/2);

        //update offset
        offset.x += SPACING.width;
        if (offset.x > self.view.bounds.size.width - SPACING.width)
        {
            offset.x = 0;
            offset.y += SPACING.height;
        }
    }
}

@end
