//
//  UtilityFunction.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/27.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "UtilityFunction.h"
#import "FixtureType.h"

@implementation UtilityFunction
+(NSString *)TimeStamp{
    NSDate *now=[NSDate date];
    NSString*datestr=[now descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
    float ss=([now timeIntervalSince1970]-(long)[now timeIntervalSince1970])*1000;
    return [NSString stringWithFormat:@"%@.%03d",datestr,(int)ss];
}


+(NSDate *)getDateWithString:(NSString *)sDate{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"%Y-%m-%d %H:%M:%S.%03s"];
    NSDate *date = [dateFormatter dateFromString:sDate];
    return date;
}


@end
