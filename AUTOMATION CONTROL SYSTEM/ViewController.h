//
//  ViewController.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/22.
//  Copyright © 2017年 coco. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (weak) IBOutlet NSTextField *tfSpeed;
- (IBAction)actButtonRead:(id)sender;
- (IBAction)actButtonSet:(id)sender;
@property (weak) IBOutlet NSPopUpButton *popRetestStrategy;
- (IBAction)actPopRetestStrategy:(id)sender;
@property (weak) IBOutlet NSPopUpButton *popProductMode;
- (IBAction)actPopProductMode:(id)sender;
@property (weak) IBOutlet NSTextField *tfFailRate;
@property (weak) IBOutlet NSTextField *tfAvailableFixture;
@property (weak) IBOutlet NSImageView *imageFixture1;
@property (weak) IBOutlet NSImageView *imageFixture2;
@property (weak) IBOutlet NSImageView *imageFixture3;
@property (weak) IBOutlet NSImageView *imageFixture4;
@property (weak) IBOutlet NSImageView *imageFixture5;

@property (weak) IBOutlet NSImageView *imageFixture6;
@property (weak) IBOutlet NSImageView *imageFixture7;
@property (weak) IBOutlet NSImageView *imageFixture8;
@property (weak) IBOutlet NSImageView *imageBin1;
@property (weak) IBOutlet NSImageView *imageBin2;
@property (weak) IBOutlet NSImageView *imageBin3;
@property (weak) IBOutlet NSImageView *imageBin4;
@property (weak) IBOutlet NSImageView *imageBin5;
@property (weak) IBOutlet NSImageView *imageConveyor;
@property (weak) IBOutlet NSImageView *imageRobot;

@end

