//
//  ConfigurationFile.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/22.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "ConfigurationFile.h"
static ConfigurationFile *shareConfigurationFile = NULL;
@implementation ConfigurationFile

+(ConfigurationFile *)shareConfigurationFile{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareConfigurationFile = [[ConfigurationFile alloc] init];
        
    });
    return shareConfigurationFile;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        NSString *file = [[NSBundle mainBundle] pathForResource:@"ACSConfiguration" ofType:@"plist"];
        dConfig = [[NSDictionary alloc] initWithContentsOfFile:file] ;
    }
    return self;
}//

-(NSDictionary *)getFixtureMapping{
    return [dConfig valueForKey:@"FixtureMapping"];
}

-(NSString *)getRobotSpeed{
    return [[dConfig valueForKey:@"TestSetting"] valueForKey:@"RobotSpeed"];
}

-(NSString *)getProductMode{
    return [[dConfig valueForKey:@"TestSetting"] valueForKey:@"ProductMode"];
}

-(NSString *)getRetestStrategy{
    return [[dConfig valueForKey:@"TestSetting"] valueForKey:@"RetestStrategy"];
}
-(NSString *)getFailRate{
    return [[dConfig valueForKey:@"AlarmSetting"] valueForKey:@"FailRate"];
}

-(NSString *)getAvailableFixture{
    return [[dConfig valueForKey:@"AlarmSetting"] valueForKey:@"AvailableFixture"];
}

-(NSString *)getAuditUnits{
    return [[dConfig valueForKey:@"AuditGRRSetting"] valueForKey:@"Units"];
}

-(NSString *)getAuditTimes{
    return [[dConfig valueForKey:@"AuditGRRSetting"] valueForKey:@"Times"];
}
-(NSDictionary *)getBinLocateSetting{
    return [dConfig valueForKey:@"BinLocateSetting"];
}

-(PLCType)getPlcTypeWithIP:(NSString *)sIP{
    NSDictionary *dIP = [dConfig valueForKey:@"IPAndPortSetting"];
    for (NSString *akey in dIP) {
        if ([[dIP valueForKey:akey] isEqualToString:sIP]) {
            if ([akey isEqualToString:@"RobotIP"]) {
                return robot;
            }else if ([akey isEqualToString:@"ConveyorIP"]){
                return conveyor;
            }
        }
    }
    return undefine;
}

-(NSString *)getRobotIP{
    return [[dConfig valueForKey:@"IPAndPortSetting"] valueForKey:@"RobotIP"];
}

-(NSString *)getConveyorIP{
    return [[dConfig valueForKey:@"IPAndPortSetting"] valueForKey:@"ConveyorIP"];
}
@end
