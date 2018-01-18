//
//  MySql.h
//  TestORSSerialPort
//
//  Created by apple on 17/9/19.
//  Copyright © 2017年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface MySqlManager : NSObject{
    sqlite3 *mysqlite;
}
+(MySqlManager *)shareManager;

/*
 创建数据库和表，表包括俩个表，一个治具表，一个测试记录表。治具表包括当前治具状态，测试pass&fail次数，测试时间，空闲时间，PLCName
 测试记录表包括SN,复测机制，第一次测试治具，第一次结果，第一次开始时间，第一次结束时间，第二次测试治具，第二次测试结果，第二次开始时间，第二次结束时间，第三次测试治具，第三次测试结果，第三次开始时间，第三次结束时间
 */


//http://www.w3school.com.cn/sql/sql_top.asp
/*INSERT INTO table_name (列1, 列2,...) VALUES (值1, 值2,....)*/
/*UPDATE Person SET FirstName = 'Fred' WHERE LastName = 'Wilson' */
/*DELETE FROM Person WHERE LastName = 'Wilson' */
/*SELECT * FROM Persons WHERE City LIKE 'N%'*/
-(BOOL)setupTable:(NSString *)tableName andColumns:(NSString *)columns;
/*
 setup fixture table , the fixture name is from config file ,it means the fixture name is unique and can't be change,PLCName can be changed when remapping
 columns:
 fixturename unique
 stationName (maybe we will get stationName from client and we can map stationname to fixtue name)
 PLCname(plcname may be different from fixturename)
 
 */
-(BOOL)setupFixtureTabel;

-(BOOL)setupTestHistoryTable;
/*
 创建fixture的表，fixture名称固定，读取配置文件更新表，插入所有fixture名称
 */

-(BOOL)createFixtureNameToFixtureTable:(NSDictionary *)dConfig;

/*
 when cycle start what we need do is:
 1.update FixtureTable lastUpdateTime = currenttime if CurrentStatus=init
 2.
 */
-(BOOL)updateTableWhenCycleStart;
/*
 when re-mapping need update FixtureTable and config file
 */
-(BOOL)updateStationNameToFixtureTable:(NSString *)fixtureName
                        andStationName:(NSString *)stationName;


-(BOOL)updateStatus:(NSString *)sqlcommand;

-(NSArray *)selectFixtureTableCommand:(NSString *)selectCommand;
//get all idle fixture and order by test count, when needed should test in less count fixture
-(NSArray *)getIdleFixturesFromFixtureTable;
//select pass/fail count test/idle time to show in ui
-(NSDictionary *)getFixturesTestCountFromFixtureTable;

-(NSArray *)getMessgaeWithSerialNum:(NSString *)sn andfixtureName:(NSString *)fixtureName;
-(NSString *)updateFixtureTableWhenBeginTest:(NSString *)sdate
                                andSerialNum:(NSString *)serialNum
                              andFixtureName:(NSString *)fixtureName
                                    andDUTID:(NSString *)sDUTID;
/*
 when insert a new test process,what we need to is :
 1.select idletime and lastupdatetime from fixturetable
 2.update fixture table the sn ,fixturename,dutid,set idle time = idletime + currenttime - lastupdatetime
 3.insert test history the sn ,firstfixturename ,dutid,firststarttime,RetestStrategy
 */
-(BOOL)insertFisrtTestHistory:(NSString *)serialNum
               andfixtureName:(NSString *)fixtureName
            andRetestStrategy:(NSString *)retestStrategy;

-(NSString *)updateFixtureTableWhenFinishTestWithSerialNum:(NSString *)serialNum
                                            andFixtureName:(NSString *)fixtureName
                                             andTestResult:(NSString *)result
                                                   andDate:(NSString *)sdate;
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
               andTestResult:(NSString *)result;
/*
 when unload ok update status to idle and clear sn and dutid
 */
-(BOOL)updateFixtureTableIdle:(NSString *)PLCName;



-(BOOL)updateSecondTestHistory:(NSString *)serialNum
                andfixtureName:(NSString *)fixtureName
            andLastfixtureName:(NSString *)lastFixtureName
                      andDUTID:(NSString *)DUTID;

-(BOOL)updateSecondTestResultHistory:(NSString *)serialNum
                      andfixtureName:(NSString *)fixtureName
                  andLastfixtureName:(NSString *)lastFixtureName
                       andTestResult:(NSString *)result;

-(BOOL)updateThirdTestHistory:(NSString *)serialNum
               andfixtureName:(NSString *)fixtureName
           andLastfixtureName:(NSString *)lastFixtureName
                     andDUTID:(NSString *)DUTID;

-(BOOL)updateThirdTestResultHistory:(NSString *)serialNum
                     andfixtureName:(NSString *)fixtureName
                 andLastfixtureName:(NSString *)lastFixtureName
                      andTestResult:(NSString *)result;
-(NSArray *)selectTestHistoryCommand:(NSString *)selectCommand;



@end
