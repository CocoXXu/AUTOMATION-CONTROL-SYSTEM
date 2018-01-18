//
//  ConfigurationFile.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/22.
//  Copyright © 2017年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FixtureType.h"

@interface ConfigurationFile : NSObject{
    NSDictionary *dConfig;
}
/**
 single mode,the class must be create only one time.if class is not exsit ,create it ,else return;
 the class is get config from resource file ACSConfiguration.plist
 @result ConfigurationFile --> return self
 */

+(ConfigurationFile *)shareConfigurationFile;
/*
 FixtureMapping is the fixture num mapping the station fixture ,eg. fixture1 can mapping RHAC01_01_01 means fixture1 is the name for mac mini (rh01_01)'s first fixture.
 */
-(NSDictionary *)getFixtureMapping;
/*
 robot speed must between 0-100 when set
 */
-(NSString *)getRobotSpeed;
/*
 product mode conatains TEST,GRR,Audit
 */
-(NSString *)getProductMode;
/*
 Retest Strategy conatains AA,AAB,ABC
 */
-(NSString *)getRetestStrategy;
/*
 system will alarm when >= Fail Rate
 */
-(NSString *)getFailRate;
/*
 system will alarm when <= AvailableFixture
 */
-(NSString *)getAvailableFixture;
/*
 Audit or GRR need units
 */
-(NSString *)getAuditUnits;
/*
 Audit or GRR need test times
 */
-(NSString *)getAuditTimes;
/*
 BinLocateSetting
 */
-(NSDictionary *)getBinLocateSetting;
/*
 conveyor = 0,
 robot,
 */
-(PLCType)getPlcTypeWithIP:(NSString *)sIP;
/*
 robot ip address
 */
-(NSString *)getRobotIP;
/*
 conveyor ip address
 */
-(NSString *)getConveyorIP;
@end
