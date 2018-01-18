//
//  RunProcess.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/27.
//  Copyright © 2017年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RunProcess : NSObject{
    BOOL bRunFlag;
}

/*
 1. conveyor is ready to pick
 2. fixture is idle to load
 3. server is running
 4. robot is ok to run
 */
@property int readyToPick;


-(instancetype)init;

@end
