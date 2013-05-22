//
//  ViewController.m
//  SpritesDemo
//
//  Created by Nick Lockwood on 18/05/2013.
//  Copyright (c) 2013 Charcoal Design. All rights reserved.
//

#import "ViewController.h"
#import "LSImageMap.h"
#import <QuartzCore/QuartzCore.h>


@interface ViewController ()

@property (nonatomic, strong) LSImageMap *imageMap;

@end


@implementation ViewController

@synthesize imageMap = _imageMap;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageMap = [LSImageMap imageMapWithContentsOfFile:@"lostgarden.plist"];
    self.tableView.rowHeight = 80.0f;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.imageMap imageCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //get cell
    NSString *const CellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"SpriteCell"
                                              owner:nil
                                            options:nil] lastObject];
    }
    
    //set image (note that we don't set the dimensions here)
    NSString *name = [self.imageMap imageNameAtIndex:indexPath.row];
    LSImage *image = [self.imageMap imageNamed:name];
    [[cell viewWithTag:1].layer setContentsWithLSImage:image];
    
    //set text
    ((UILabel *)[cell viewWithTag:2]).text = name;
    
    return cell;
}


@end
