//
//  RunProcess.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/27.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "RunProcess.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "MySqlManager.h"
#import "FixtureType.h"
#import "ViewController.h"

@implementation RunProcess

-(instancetype)init{
    self = [super init];
//    if (self) {
//        <#statements#>
//    }
    
    return self;
}

-(PLCType)getPlcType:(NSString *)location{
    /*
     conveyor = 0,
     robot,
     fixture1 = 2,
     fixture2,
     fixture3,
     fixture4,
     fixture5,
     fixture6,
     fixture7,
     fixture8 = 9,
     undefine
     */
    if ([location.lowercaseString isEqualToString:@"conveyor"]) {
        return conveyor;
    }else if ([location.lowercaseString isEqualToString:@"robot"]){
        return robot;
    }else if ([location.lowercaseString isEqualToString:@"fixture1"]){
        return fixture1;
    }else if ([location.lowercaseString isEqualToString:@"fixture2"]){
        return fixture2;
    }else if ([location.lowercaseString isEqualToString:@"fixture3"]){
        return fixture3;
    }else if ([location.lowercaseString isEqualToString:@"fixture4"]){
        return fixture4;
    }else if ([location.lowercaseString isEqualToString:@"fixture5"]){
        return fixture5;
    }else if ([location.lowercaseString isEqualToString:@"fixture6"]){
        return fixture6;
    }else if ([location.lowercaseString isEqualToString:@"fixture7"]){
        return fixture7;
    }else{
        return undefine;
    }
}

-(void)startMainProcess{
    int state = 0;
    bRunFlag = YES;
    NSMutableArray *aReadySignal = [[NSMutableArray alloc] initWithCapacity:0];
    NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:@"conveyor",@"location", nil];
    NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:@"fixture2",@"location", @"12345678",@"serialnum",@"pass",@"result",nil];
    [aReadySignal addObject:@"conveyor"];
    NSString *nextFixtureName = @"";
    while (1) {
        switch (state) {
            case 0://get dut ready signal,(dut ready on conveyor and dut finished test in fixture),will collect ready signal in array
                if ([aReadySignal count] > 0) {//has dut ready signal,should pick wait for next step?
                    //TODO send message to robot to do pick or load
                    NSDictionary *dictTake = [aReadySignal objectAtIndex:0];
                    PLCType type = [self getPlcType:[dictTake valueForKey:@"location"]];
                    state = 1;
                }
                break;
            
            /*
             dut ready from fixture
             1. result to pass->need a bin to bin
             2. result to fail->need a fixture to load(according to retest)
             dut ready from conveyor
             1.need a fixture to load
            */
            case 1:
            {
                NSDictionary *dictTake = [aReadySignal objectAtIndex:0];
                PLCType type = [self getPlcType:[dictTake valueForKey:@"location"]];
                NSArray *aIdleFixture = [[MySqlManager shareManager] getIdleFixturesFromFixtureTable];//get idle fixture
                
                if (type > 1 && type < 10) {// ready from fixture and result = pass
                    if ([[dictTake valueForKey:@"result"] isEqualToString:@"pass"]) {//pass bin to bin
                        state = 3;
                    }else{ //fail test(1.fail but can be AAB ,2 fail 3 times
                        state = 4;
                    }
                }else{
                    if (type ==0 && aIdleFixture.count > 0) {//from conveyor and has free idle fixture
                        nextFixtureName = [aIdleFixture objectAtIndex:0];
                        state = 2;
                        break;
                    }
                }
                
            }
                
                break;
                
            case 2://idle fixture is ready , will create a command to load
            {
                //TODO ,create a command to load set state = 10
            }
                
                break;
            case 3://ok bin is ok to bin
            {
                
            }
                
                break;
                
            case 4://fail test(1.fail but can be AAB ,2 fail 3 times
            {
                NSArray *aIdleFixture = [[MySqlManager shareManager] getIdleFixturesFromFixtureTable];//get idle fixture
                NSDictionary *dictTake = [aReadySignal objectAtIndex:0];
                NSArray *aTestMessage = [[MySqlManager shareManager] getMessgaeWithSerialNum:[dictTake valueForKey:@"serialnum"] andfixtureName:[dictTake valueForKey:@"location"]];
                if (aTestMessage.count  == 16) {//message get ok
                    NSString *retest = [aTestMessage objectAtIndex:3];
                    NSString *nextFixture = @"";
                    if ([[aTestMessage objectAtIndex:13] isEqualToString:@"fail"]) {// all fails aab
                        state = 5;//need bin to ng bin
                    }else if ([[aTestMessage objectAtIndex:9] isEqualToString:@"fail"]){//aa fail
                        NSString *fFixture = [aTestMessage objectAtIndex:4];
                        NSString *sFixture = [aTestMessage objectAtIndex:8];
                        for (int i = 0; i < aIdleFixture.count; i++) {
                            if ([aIdleFixture[i] isNotEqualTo:fFixture] && [aIdleFixture[i] isNotEqualTo:sFixture]) {
                                nextFixture = aIdleFixture[i];
                                break;
                            }
                        }
                    }else if ([[aTestMessage objectAtIndex:5] isEqualToString:@"fail"]){//a fail
                        NSString *fFixture = [aTestMessage objectAtIndex:4];
                        for (int i = 0; i < aIdleFixture.count; i++) {
                            if (([retest.uppercaseString rangeOfString:@"AA"].location == NSNotFound) && ([aIdleFixture[i] isNotEqualTo:fFixture])) {//ABC &&  not the same then set next fixture
                                    nextFixture = aIdleFixture[i];
                                state = 2;//idle fixture is ready ,will create command to load
                                    break;
                            }else if (([retest.uppercaseString rangeOfString:@"AA"].location != NSNotFound) && ([aIdleFixture[i] isEqualToString:fFixture])){//AAB/AA and the same then set next fixture
                                nextFixture = aIdleFixture[i];
                                state = 2;//idle fixture is ready ,will create command to load
                                break;
                            }
                            
                        }
                    }
                }else{
                    //todo alert error?
                }
            
            }
                
                break;
            
            case 5: //ng bin is ok to bin
                //todo
                break;
                
            case 10://send command to robot
    
            default:
                break;
        }
        if (bRunFlag == NO) {//need send stop command to robot and conveyor and fixture??
            break;
        }
    }
}

-(void)stopProcess{
    bRunFlag = NO;
}
@end
