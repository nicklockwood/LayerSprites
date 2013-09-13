//
//  ViewController.m
//  DrawingDemo
//
//  Created by Nick Lockwood on 20/05/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "ViewController.h"
#import "LSImageMap.h"
#import "LSImageView.h"

#define SPACING CGSizeMake(101,171)

@interface ViewController ()

@property (nonatomic, strong) LSImageMap *imageMap;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageMap = [LSImageMap imageMapWithContentsOfFile:@"lostgarden"];
    
    for (NSString *name in self.imageMap)
    {
        //get sprite
        LSImage *image = self.imageMap[name];
        
        //create view
        LSImageView *imageView = [[LSImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0, 0, SPACING.width, SPACING.height);
        imageView.layer.borderColor = [UIColor blackColor].CGColor;
        imageView.layer.borderWidth = 1;
        [self.view addSubview:imageView];
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
        UIView *view = self.view.subviews[i];
        view.center = CGPointMake(offset.x + SPACING.width/2, offset.y + SPACING.height/2);

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
