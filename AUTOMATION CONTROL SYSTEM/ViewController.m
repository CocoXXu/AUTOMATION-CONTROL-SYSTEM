//
//  ViewController.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/22.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "ViewController.h"
#import "ConfigurationFile.h"
#import "PLCSocketServer.h"
#import "FixtureSocketServer.h"
#import "MySqlManager.h"
#import "FixtureType.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFixtureStatus:) name:@"socketStatus" object:nil];
    [PLCSocketServer shareIntance];
    [FixtureSocketServer shareIntance];
    [MySqlManager shareManager];
    // Do any additional setup after loading the view.
}
-(void)updateFixtureStatus:(NSNotification *)notification{
    NSString *status = [[notification userInfo] valueForKey:@"status"];
    
    PLCType type = [[[notification userInfo] valueForKey:@"sockethost"] intValue];
    NSString *snapname = [NSString stringWithFormat:@"%@%d.png",status,type];
    switch (type) {
        case 0:
            //conveyor
            [_imageConveyor setImage:[NSImage imageNamed:snapname]];
            break;
        case 1:
            //robot
            [_imageRobot setImage:[NSImage imageNamed:snapname]];
            break;
        default:
            break;
    }
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)actButtonRead:(id)sender {
}

- (IBAction)actButtonSet:(id)sender {
}
- (IBAction)actPopRetestStrategy:(id)sender {
}
- (IBAction)actPopProductMode:(id)sender {
}
@end
