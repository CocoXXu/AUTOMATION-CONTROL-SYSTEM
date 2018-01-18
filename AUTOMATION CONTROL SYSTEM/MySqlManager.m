//
//  MySql.m
//  TestORSSerialPort
//
//  Created by apple on 17/9/19.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "MySqlManager.h"
#import "ConfigurationFile.h"
#import "UtilityFunction.h"
#import "FixtureType.h"



static MySqlManager *shareManager = NULL;
@implementation MySqlManager

+(MySqlManager *)shareManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^(void){
        shareManager = [[MySqlManager alloc] init];
        

    });
    return shareManager;
}

/*
 创建数据库和表，表包括俩个表，一个治具表，一个测试记录表。治具表包括当前治具状态，测试pass&fail次数，测试时间，空闲时间，PLCName
 测试记录表包括SN,复测机制，第一次测试治具，第一次结果，第一次开始时间，第一次结束时间，第二次测试治具，第二次测试结果，第二次开始时间，第二次结束时间，第三次测试治具，第三次测试结果，第三次开始时间，第三次结束时间
 */
-(instancetype)init{
    self = [super init];
    if (self) {
        NSString *filename = @"/Users/apple/Desktop/RHACACS.sqlite";
        int status = sqlite3_open([filename UTF8String], &mysqlite);
        if (status != SQLITE_OK) {
            return nil;
        }
        if (![self setupFixtureTabel]) {
            return nil;
        }else{
            NSDictionary *dconfig = [[ConfigurationFile shareConfigurationFile] getFixtureMapping];
            [self createFixtureNameToFixtureTable:dconfig];
        }
        if (![self setupTestHistoryTable]) {
            return nil;
        }
    }
    return self;
}

//http://www.w3school.com.cn/sql/sql_top.asp
/*INSERT INTO table_name (列1, 列2,...) VALUES (值1, 值2,....)*/
/*UPDATE Person SET FirstName = 'Fred' WHERE LastName = 'Wilson' */
/*DELETE FROM Person WHERE LastName = 'Wilson' */
/*SELECT * FROM Persons WHERE City LIKE 'N%'*/
-(BOOL)setupTable:(NSString *)tableName andColumns:(NSString *)columns{
    //创表语句，IF NOT EXISTS防止创建重复的表，AUTOINCREMENT是自动增长关键字，real是数字类型
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ %@;",tableName,columns];
    
    //保存错误信息的变量
    
    char * errMsg=NULL;
    
    /*
     
     sqlite3_exec需要传递5个参数，第一个参数是数据库引用即sqlite3* _shop,第二个参数是要执行的sql语句,
     
     第三个参数是执行完sql语句后要执行的函数，第四个参数是执行完sql语句后要执行的函数的参数，第五个参数是执行完sql语句后的报错信息。
     
     */
    
    sqlite3_exec(mysqlite, sql.UTF8String, NULL, NULL, &errMsg);
    
    if(errMsg)//如果存在报错信息，代表语句执行失败，比判断枚举值要更简单一些
    {
        return NO;
        
    }else{
        return YES;
    }
}
/*
 setup fixture table , the fixture name is from config file ,it means the fixture name is unique and can't be change,PLCName can be changed when remapping
 columns:
 fixturename unique
 stationName (maybe we will get stationName from client and we can map stationname to fixtue name)
 PLCname(plcname may be different from fixturename)
 
 */
-(BOOL)setupFixtureTabel{
    BOOL status =[self setupTable:@"FixtureTable" andColumns:@"(id integer PRIMARY KEY AUTOINCREMENT,fixtureName text NOT NULL,stationName text NOT NULL,PLCName text NOT NULL,CurrentStatus text NOT NULL,passCount integer default 0,failCount integer default 0,testTime integer default 0,idleTime integer default 0,DUTID text,SN text,lastUpdateTime text"];
    return status;
}

-(BOOL)setupTestHistoryTable{
    NSString *columns = @"(id integer PRIMARY KEY AUTOINCREMENT,DUTID text NOT NULL,SN test NOT NULL,RetestStrategy text NOT NULL, FirstFixture text,FirstResult text,FirstBeginTime text,FirstEndTime text,SecondFixture text,SecondResult text,SecondBeginTime text,SecondEndTime text,ThirdFixture text,ThirdResult text,ThirddBeginTime text,ThirdEndTime text)";
    BOOL status = [self setupTable:@"testHistoryTable" andColumns:columns];
    return status;
}
/*
 创建fixture的表，fixture名称固定，读取配置文件更新表，插入所有fixture名称
 */

-(BOOL)createFixtureNameToFixtureTable:(NSDictionary *)dConfig{
    for (NSString *afitureName in dConfig) {
        NSString *sqlcommand =[NSString stringWithFormat:@"insert into FixtureTable (fixtureName,StationName，PLCName,CurrentStatus) Values('%@','%@','%@','Init')",afitureName,[[dConfig valueForKey:afitureName] valueForKey:@"StationName"],[[dConfig valueForKey:afitureName] valueForKey:@"PLCName"]];
        char * errMsg=NULL;
        BOOL sqlstatus = sqlite3_exec(mysqlite,sqlcommand.UTF8String,NULL,NULL,&errMsg);
        if(sqlstatus != SQLITE_OK) {
            return NO;
        }
    }
    return YES;
}

/*
 when cycle start what we need do is:
 1.update FixtureTable lastUpdateTime = currenttime if CurrentStatus=init
 2.
 */
-(BOOL)updateTableWhenCycleStart{
    NSString  *sdate = [UtilityFunction TimeStamp];
    NSString *supdatecommand = [NSString stringWithFormat:@"update FixtureTable lastUpdateTime = '%@' where CurrentStatus ='init'",sdate];
    return ([self updateStatus:supdatecommand]);
}
/*
 when re-mapping need update FixtureTable and config file
 */
-(BOOL)updateStationNameToFixtureTable:(NSString *)fixtureName
                        andStationName:(NSString *)stationName{
    NSString *supdateCommand = [NSString stringWithFormat:@"update FixtureTable StationName = '%@' where fixtureName = '%@'",stationName,fixtureName];
    return [self updateStatus:supdateCommand];
}


-(BOOL)updateStatus:(NSString *)sqlcommand{
    char * errMsg=NULL;
    return (sqlite3_exec(mysqlite,sqlcommand.UTF8String,NULL,NULL,&errMsg));
}

-(NSArray *)getMessgaeWithSerialNum:(NSString *)sn andfixtureName:(NSString *)fixtureName{
    NSString *selectCommand = [NSString stringWithFormat:@"select DUTID from FixtureTable where SN ='%@' and fixtureName = '%@'",sn,fixtureName];
    sqlite3_stmt *stmt=NULL;
    NSString *dutID =@"";
    NSArray *adutMessage = [[NSArray alloc] init];
    int status = sqlite3_prepare_v2(mysqlite, selectCommand.UTF8String, -1, &stmt, NULL);
    if(status == SQLITE_OK){
        while(sqlite3_step(stmt) == SQLITE_ROW)//成功指向一条记录
        {
            dutID =[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 0)];
        }
    }
    if ([dutID isNotEqualTo:@""]) {
        selectCommand = [NSString stringWithFormat:@"select * from  where DUTID='%@'",dutID];
        adutMessage = [self selectTestHistoryCommand:selectCommand];
    }
    return adutMessage;
}

-(NSArray *)selectFixtureTableCommand:(NSString *)selectCommand{
    sqlite3_stmt *stmt=NULL;
    NSMutableArray *arrayMessage = [[NSMutableArray alloc] initWithCapacity:0];
    int status = sqlite3_prepare_v2(mysqlite, selectCommand.UTF8String, -1, &stmt, NULL);
    if(status == SQLITE_OK){
        while(sqlite3_step(stmt) == SQLITE_ROW)//成功指向一条记录
        {
            NSMutableDictionary *dMessage = [[NSMutableDictionary alloc] init];
            [dMessage setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 0)] forKey:@"ID"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 1)] forKey:@"fixtureName"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 2)] forKey:@"stationName"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 3)] forKey:@"PLCName"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 4)] forKey:@"CurrentStatus"];
            [dMessage setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 5)] forKey:@"passCount"];
            [dMessage setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 6)] forKey:@"failCount"];
            [dMessage setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 7)] forKey:@"testTime"];
            [dMessage setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 8)] forKey:@"idleTime"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 9)] forKey:@"DUTID"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 10)] forKey:@"SN"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 11)] forKey:@"lastUpdateTime"];
            [arrayMessage addObject:dMessage];
        }
    }
    return arrayMessage;
}
//get all idle fixture and order by test count, when needed should test in less count fixture
-(NSArray *)getIdleFixturesFromFixtureTable{
    NSString *selectCommand = @"select PLCName,passCount+failCount as totalcount from FixtureTable where CurrentStatus=idle ORDER BY totalcount";
    sqlite3_stmt *stmt=NULL;
    NSMutableArray *arrayMessage = [[NSMutableArray alloc] initWithCapacity:0];
    int status = sqlite3_prepare_v2(mysqlite, selectCommand.UTF8String, -1, &stmt, NULL);
    if(status == SQLITE_OK){
        while(sqlite3_step(stmt) == SQLITE_ROW)//成功指向一条记录
        {
            [arrayMessage addObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 0)]];
        }
    }
    return arrayMessage;
    
}
//select pass/fail count test/idle time to show in ui
-(NSDictionary *)getFixturesTestCountFromFixtureTable{
    NSString *selectCommand = @"select fixtureName,passCount,failCount,testTime,idleTime from FixtureTable";
    sqlite3_stmt *stmt=NULL;
    NSMutableDictionary *dMessage = [[NSMutableDictionary alloc] initWithCapacity:0];
    int status = sqlite3_prepare_v2(mysqlite, selectCommand.UTF8String, -1, &stmt, NULL);
    if(status == SQLITE_OK){
        while(sqlite3_step(stmt) == SQLITE_ROW)//成功指向一条记录
        {
            NSDictionary *dfixture = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:sqlite3_column_int(stmt, 1)],@"passCount", [NSNumber numberWithInt:sqlite3_column_int(stmt, 2)],@"failCount",[NSNumber numberWithInt:sqlite3_column_int(stmt, 3)],@"testTime",[NSNumber numberWithInt:sqlite3_column_int(stmt, 4)],@"idleTime",nil];
            [dMessage setObject:dfixture forKey:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 0)]];
        }
    }
    return dMessage;
    
}
-(NSString *)updateFixtureTableWhenBeginTest:(NSString *)sdate
                                andSerialNum:(NSString *)serialNum
                              andFixtureName:(NSString *)fixtureName
                                    andDUTID:(NSString *)sDUTID{
    NSMutableString *msdate =[[NSMutableString alloc] initWithString:sdate];
    [msdate replaceOccurrencesOfString:@":" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, msdate.length)];
    [msdate replaceOccurrencesOfString:@"." withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, msdate.length)];
    [msdate replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, msdate.length)];
    if ([sDUTID isEqualToString:@""]) {
        sDUTID = [NSString stringWithFormat:@"%@%@",msdate,serialNum];//new a unique DUTID(conatains time and serialnum)
    }
    
    NSString *sFixtureCommand = [NSString stringWithFormat: @"select idleTime,lastUpdateTime from FixtureTable where fixtureName='%@'",fixtureName];
    sqlite3_stmt *stmt=NULL;
    int status = sqlite3_prepare_v2(mysqlite, sFixtureCommand.UTF8String, -1, &stmt, NULL);
    if(status == SQLITE_OK){
        while(sqlite3_step(stmt) == SQLITE_ROW)//成功指向一条记录
        {
            int idleTime = sqlite3_column_int(stmt, 0);
            NSString *slastUpdateTime = [NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 1)];
            NSDate *dlastUpdateTime = [UtilityFunction getDateWithString:slastUpdateTime];
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:dlastUpdateTime];
            idleTime +=interval;
            NSString *supdateFixtureCommand = [NSString stringWithFormat:@"update CurrentStatus='test', FixtureTable idleTime = %d,lastUpdateTime='%@',DUTID='%@' where fixtureName='%@'",idleTime,[UtilityFunction TimeStamp],sDUTID,fixtureName];
            int updateStatus = sqlite3_exec(mysqlite, supdateFixtureCommand.UTF8String, NULL, NULL, NULL);
            if (updateStatus == NO) {
                return @"";
            }
        }
    }
    return sDUTID;
}
/*
 when insert a new test process,what we need to is :
 1.select idletime and lastupdatetime from fixturetable
 2.update fixture table the sn ,fixturename,dutid,set idle time = idletime + currenttime - lastupdatetime
 3.insert test history the sn ,firstfixturename ,dutid,firststarttime,RetestStrategy
 */
-(BOOL)insertFisrtTestHistory:(NSString *)serialNum
               andfixtureName:(NSString *)fixtureName
            andRetestStrategy:(NSString *)retestStrategy{
    
    NSString *sdate = [UtilityFunction TimeStamp];
    NSString *sDUTID = [self updateFixtureTableWhenBeginTest:sdate andSerialNum:serialNum andFixtureName:fixtureName andDUTID:@""];
    if ([sDUTID isEqualToString:@""]) {
        return NO;
    }
    NSString *scommand  = [NSString stringWithFormat:@"insert into testHistoryTable (DUTID,SN,RetestStrategy,FirstFixture,FirstBeginTime) values ('%@','%@','%@','%@','%@')",sDUTID,serialNum,retestStrategy,fixtureName,sdate];
    char * errMsg=NULL;
    return sqlite3_exec(mysqlite, scommand.UTF8String, NULL, NULL, &errMsg);
}

-(NSString *)updateFixtureTableWhenFinishTestWithSerialNum:(NSString *)serialNum
                                     andFixtureName:(NSString *)fixtureName
                                      andTestResult:(NSString *)result
                                            andDate:(NSString *)sdate{
    NSString *sfixtureCommand = [NSString stringWithFormat:@"select CurrentStatus,DUTID,testTime,lastUpdateTime,passCount,failCount from FixtureTable where SN='%@'",serialNum];
    sqlite3_stmt *stmt1=NULL;
    NSString *sDUTID = nil;
    
    int status1 = sqlite3_prepare_v2(mysqlite, sfixtureCommand.UTF8String, -1, &stmt1, NULL);
    if(status1 == SQLITE_OK){
        while(sqlite3_step(stmt1) == SQLITE_ROW)//成功指向一条记录
        {
            NSString *currentStatus = [NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt1, 0)];
            sDUTID =[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt1, 1)];
            int itesttime = sqlite3_column_int(stmt1, 2);
            NSString *slastupdatetime =[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt1, 3)];
            NSDate *datelastUpdateTime = [UtilityFunction getDateWithString:slastupdatetime];
            itesttime += [[NSDate date] timeIntervalSinceDate:datelastUpdateTime];
            NSString *supdateFixtureCommand ;
            if ([currentStatus isNotEqualTo:@"test"]) {
                return @"";
            }
            if ([result.lowercaseString isEqualToString:@"pass"]) {
                int ipasscount =sqlite3_column_int(stmt1, 4);
                supdateFixtureCommand = [NSString stringWithFormat:@"update CurrentStatus='pass',FixtureTable testtime=%d,passCount=%d,lastUpdateTime='%@' where SN='%@'",itesttime,++ipasscount,sdate,serialNum];
            }else{
                int ifailCount =sqlite3_column_int(stmt1, 5);
                supdateFixtureCommand = [NSString stringWithFormat:@"update CurrentStatus='fail',FixtureTable testtime=%d,failCount=%d,lastUpdateTime='%@' where SN='%@'",itesttime,++ifailCount,sdate,serialNum];
            }
            
            if ([self updateStatus:supdateFixtureCommand] == NO) {
                return nil;
            }
        }
    }
    return sDUTID;
}
/*
 when insert a new test process,what we need to is :
 1.select dutid,testtime and lastupdatetime,failcount,passcount from fixturetable with serialnum
 2.update fixture table the test time = test + currenttime - lastupdatetime and result(passcount/failcount+1),lastupdatetime =currenttime，dutid="",sn=""
 3.insert test history the sn ,firstfixturename ,dutid,firststarttime,RetestStrategy
 select result before update ,if result is not nil then will not update ,if result is nil ,update
 avoid re-update
 
 */
-(int)updateFisrtTestHistory:(NSString *)serialNum
               andfixtureName:(NSString *)fixtureName
            andTestResult:(NSString *)result{
    //select DUTID from FixtureTable with fixtureName
    NSString *sdate = [UtilityFunction TimeStamp];
    NSString *sDUTID = [self updateFixtureTableWhenFinishTestWithSerialNum:serialNum andFixtureName:fixtureName andTestResult:result andDate:sdate];
    
    if (sDUTID == nil) {
        return insertNG;
    }else if ([sDUTID isEqualToString:@""]){
        return insertRE;
    }
    NSString *scommand  = [NSString stringWithFormat:@"update testHistoryTable FirstResult = '%@',FirstEndTime='%@' where DUTID = '%@'",result,sdate,sDUTID];
    char * errMsg=NULL;
    return sqlite3_exec(mysqlite, scommand.UTF8String, NULL, NULL, &errMsg);
}
/*
 when unload ok update status to idle and clear sn and dutid
 */
-(BOOL)updateFixtureTableIdle:(NSString *)PLCName{
    NSString *supdateCommand = [NSString stringWithFormat:@"update FixtureTable CurrentStatus='idle',SN='',DUTID='' where PLCName = '%@'",PLCName];
    return [self updateStatus:supdateCommand];
    
}



-(BOOL)updateSecondTestHistory:(NSString *)serialNum
                andfixtureName:(NSString *)fixtureName
                andLastfixtureName:(NSString *)lastFixtureName
                      andDUTID:(NSString *)DUTID
{
    NSString *sdata = [UtilityFunction TimeStamp];
    NSString *sDUTID = [self updateFixtureTableWhenBeginTest:sdata andSerialNum:serialNum andFixtureName:fixtureName andDUTID:DUTID];
    if ([sDUTID isEqualToString:@""]) {
        return NO;
    }
    NSString *scommand  = [NSString stringWithFormat:@"update testHistoryTable SecondFixture = '%@',SecondBeginTime='%@' where DUTID = '%@'",lastFixtureName,sdata,DUTID];
    char * errMsg=NULL;
    return sqlite3_exec(mysqlite, scommand.UTF8String, NULL, NULL, &errMsg);
}

-(BOOL)updateSecondTestResultHistory:(NSString *)serialNum
                andfixtureName:(NSString *)fixtureName
                  andLastfixtureName:(NSString *)lastFixtureName
                       andTestResult:(NSString *)result
{
    NSString *sdata = [UtilityFunction TimeStamp];
    NSString *sDUTID =[self updateFixtureTableWhenFinishTestWithSerialNum:serialNum andFixtureName:fixtureName andTestResult:result andDate:sdata];
    if (sDUTID == nil) {
        return insertNG;
    }else if ([sDUTID isEqualToString:@""]){
        return insertRE;
    }
    NSString *scommand  = [NSString stringWithFormat:@"update testHistoryTable SecondResult = '%@',SecondEndTime='%@' where DUTID = '%@'",result,sdata,sDUTID];
    char * errMsg=NULL;
    return sqlite3_exec(mysqlite, scommand.UTF8String, NULL, NULL, &errMsg);
    
}

-(BOOL)updateThirdTestHistory:(NSString *)serialNum
               andfixtureName:(NSString *)fixtureName
           andLastfixtureName:(NSString *)lastFixtureName
                     andDUTID:(NSString *)DUTID
{
    NSString *sdata = [UtilityFunction TimeStamp];
    NSString *sDUTID = [self updateFixtureTableWhenBeginTest:sdata andSerialNum:serialNum andFixtureName:fixtureName andDUTID:DUTID];
    if ([sDUTID isEqualToString:@""]) {
        return NO;
    }
    NSString *scommand  = [NSString stringWithFormat:@"update testHistoryTable ThirdFixture = '%@',ThirdBeginTime='%@' where DUTID = '%@'",lastFixtureName,sdata,DUTID];
    char * errMsg=NULL;
    return sqlite3_exec(mysqlite, scommand.UTF8String, NULL, NULL, &errMsg);
}

-(BOOL)updateThirdTestResultHistory:(NSString *)serialNum
                      andfixtureName:(NSString *)fixtureName
                  andLastfixtureName:(NSString *)lastFixtureName
                       andTestResult:(NSString *)result
{
    NSString *sdata = [UtilityFunction TimeStamp];
    NSString *sDUTID =[self updateFixtureTableWhenFinishTestWithSerialNum:serialNum andFixtureName:fixtureName andTestResult:result andDate:sdata];
    if (sDUTID == nil) {
        return insertNG;
    }else if ([sDUTID isEqualToString:@""]){
        return insertRE;
    }
    NSString *scommand  = [NSString stringWithFormat:@"update testHistoryTable ThirdResult = '%@',ThirdEndTime='%@' where DUTID = '%@'",result,sdata,sDUTID];
    char * errMsg=NULL;
    return sqlite3_exec(mysqlite, scommand.UTF8String, NULL, NULL, &errMsg);
    
}
-(NSArray *)selectTestHistoryCommand:(NSString *)selectCommand{
    sqlite3_stmt *stmt=NULL;
    NSMutableArray *arrayMessage = [[NSMutableArray alloc] initWithCapacity:0];
    int status = sqlite3_prepare_v2(mysqlite, selectCommand.UTF8String, -1, &stmt, NULL);
    if(status == SQLITE_OK){
        while(sqlite3_step(stmt) == SQLITE_ROW)//成功指向一条记录
        {
            NSMutableDictionary *dMessage = [[NSMutableDictionary alloc] init];
            [dMessage setObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, 0)] forKey:@"ID"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 1)] forKey:@"DUTID"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 2)] forKey:@"SN"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 3)] forKey:@"RetestStrategy"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 4)] forKey:@"FirstFixture"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 5)] forKey:@"FirstResult"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 6)] forKey:@"FirstBeginTime"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 7)] forKey:@"FirstEndTime"];
            
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 8)] forKey:@"SecondFixture"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 9)] forKey:@"SecondResult"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 10)] forKey:@"SecondBeginTime"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 11)] forKey:@"SecondEndTime"];
            
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 12)] forKey:@"ThirdFixture"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 13)] forKey:@"ThirdResult"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 14)] forKey:@"ThirddBeginTime"];
            [dMessage setObject:[NSString stringWithUTF8String: (const char*)sqlite3_column_text(stmt, 15)] forKey:@"ThirdEndTime"];
            [arrayMessage addObject:dMessage];
        }
    }
    return arrayMessage;
}

@end
