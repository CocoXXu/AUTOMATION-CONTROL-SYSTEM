//
//  PLCSocketServer.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/25.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "PLCSocketServer.h"

#import "ConfigurationFile.h"

static PLCSocketServer *shareIntance = NULL;

@implementation PLCSocketServer
+(PLCSocketServer *)shareIntance{
    static dispatch_once_t once;
    dispatch_once(&once, ^(void){
        shareIntance = [[PLCSocketServer alloc] init];
    });
    return shareIntance;
}


-(instancetype)init{
    self = [super init];
    if (self) {
        self.serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *error;
        BOOL result = [self.serverSocket acceptOnPort:8006 error:&error];
        if (result != YES) {
            @throw [NSException exceptionWithName:@"socket connet error" reason:@"socket connet error" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error.description,@"error", nil]];
        }
        self.dClientSockets = [[NSMutableDictionary alloc] initWithCapacity:0];
        dDataIdentyByTag = [[NSMutableDictionary alloc] initWithCapacity:0];
        robotCommandId = 0;
        conveyorCommandId = 0;
        robotIP =[[ConfigurationFile shareConfigurationFile] getRobotIP];
        conveyorIP = [[ConfigurationFile shareConfigurationFile] getConveyorIP];
    }
    return self;
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(nonnull GCDAsyncSocket *)newSocket
{
    // 保存客户端的socket
    [self.dClientSockets setObject:newSocket forKey:newSocket.connectedHost];
    
    PLCType type = [[ConfigurationFile shareConfigurationFile] getPlcTypeWithIP:newSocket.connectedHost];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"socketStatus" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",type],@"sockethost", @"connect",@"status",nil]];
//    NSLog(@"%@:%d==%@:%d",newSocket.localHost,newSocket.localPort,newSocket.connectedHost,newSocket.connectedPort);
    [newSocket readDataWithTimeout:- 1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%@==%@:%d",sock.connectedHost,host,port);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    for (NSString *akey in self.dClientSockets.allKeys) {
        if ([[self.dClientSockets valueForKey:akey] isEqual:sock]) {
            PLCType type = [[ConfigurationFile shareConfigurationFile] getPlcTypeWithIP:akey];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketStatus" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",type],@"sockethost", @"disconnect",@"status",nil]];
            break;
        }
    }
//     NSLog(@"%@==%@",sock.localHost,err);
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //TODO
    /*
     if ip==plc && command == ready for pick
     send notification to add queue
     if ip==plc && command = heart beat
     if ip==plc && command = error
     if ip=robot and command = action ok
     if ip=robot and command = heart beat
     if ip= robot && command = error
     */
    NSMutableData *mdata;
    if (![[dDataIdentyByTag allKeys] containsObject:[NSString stringWithFormat:@"%ld",tag]]) {
        mdata = [[NSMutableData alloc] initWithCapacity:0];
    }else{
        mdata = [[NSMutableData alloc] initWithData:[dDataIdentyByTag valueForKey:[NSString stringWithFormat:@"%ld",tag]]];
    }
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",text);
    
    [sock readDataWithTimeout:- 1 tag:0];
}

-(void)sendCommandToRobotToAction:(PLCType)location{
    NSString *command = [NSString stringWithFormat:@"%d,%d",robotCommandId,location];//todo
//    NSString *robotIP = [[ConfigurationFile shareConfigurationFile] getRobotIP];
    GCDAsyncSocket *robotClient = [self.dClientSockets valueForKey:robotIP];
    [robotClient writeData:[command dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:robotCommandId];
    robotCommandId++;
}

-(BOOL)sendCommandAndReadResult:(PLCType)location withTimeOut:(int)timeout{
    int tag = robotCommandId;
    [self sendCommandToRobotToAction:location];
    NSDate *beiginTime = [NSDate date];
    while ([[NSDate date] timeIntervalSinceDate:beiginTime] < timeout) {
        NSData *data = [dDataIdentyByTag valueForKey:[NSString stringWithFormat:@"%d",tag]];
        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([message rangeOfString:@",@"].location != NSNotFound) {//recive message is ok
            [dDataIdentyByTag removeObjectForKey:[NSString stringWithFormat:@"%d",tag]];
            //todo
            return YES;
        }
    }
    return NO;
}

-(void)robotHeartBeat{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
            int tag = robotCommandId;
            GCDAsyncSocket *robotClient = [self.dClientSockets valueForKey:robotIP];
            [robotClient writeData:[@"robothearbeat" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:tag];
            NSDate *beiginTime = [NSDate date];
            BOOL bFlag = NO;
            while ([[NSDate date] timeIntervalSinceDate:beiginTime] < 200) {
                NSData *data = [dDataIdentyByTag valueForKey:[NSString stringWithFormat:@"%d",tag]];
                NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if ([message rangeOfString:@",@"].location != NSNotFound) {//recive message is ok
                    [dDataIdentyByTag removeObjectForKey:[NSString stringWithFormat:@"%d",tag]];
                    //todo
                    if ([message rangeOfString:@"error"].location != NSNotFound) {
                        //error
                        //TODO
                    }
                    bFlag = YES;
                    break;
                }
            }
            if (bFlag == NO) {//heart beat error
                //todo
            }
            [NSThread sleepForTimeInterval:60];//sleep 60 s 
        }
    });
    
}

-(void)ConveyorHeartBeat{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
            int tag = conveyorCommandId;
            GCDAsyncSocket *robotClient = [self.dClientSockets valueForKey:conveyorIP];
            [robotClient writeData:[@"conveyorheartbeat" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:tag];
            NSDate *beiginTime = [NSDate date];
            BOOL bFlag = NO;
            while ([[NSDate date] timeIntervalSinceDate:beiginTime] < 200) {
                NSData *data = [dDataIdentyByTag valueForKey:[NSString stringWithFormat:@"%d",tag]];
                NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if ([message rangeOfString:@",@"].location != NSNotFound) {//recive message is ok
                    [dDataIdentyByTag removeObjectForKey:[NSString stringWithFormat:@"%d",tag]];
                    //todo
                    if ([message rangeOfString:@"error"].location != NSNotFound) {
                        //error
                    }
                    bFlag = YES;
                    break;
                }
            }
            if (bFlag == NO) {//heart beat error
                //todo
            }
            [NSThread sleepForTimeInterval:60];//sleep 60 s
        }
    });
    
}

@end
