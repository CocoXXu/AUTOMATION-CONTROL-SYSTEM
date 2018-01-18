//
//  FixtureSocketServer.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/25.
//  Copyright © 2017年 coco. All rights reserved.
//

#import "FixtureSocketServer.h"
static FixtureSocketServer *shareIntance = NULL;
@implementation FixtureSocketServer
+(FixtureSocketServer *)shareIntance{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareIntance = [[FixtureSocketServer alloc] init];
    });
    return shareIntance;
}
-(instancetype)init{
    self = [super init];
    if (self) {
        self.serverSocket =  [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *error;
        BOOL result = [self.serverSocket acceptOnPort:8008 error:&error];
        if (result != YES) {
            @throw [NSException exceptionWithName:@"socket connet error" reason:@"socket connet error" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error.description,@"error", nil]];
        }
        self.dClientSockets = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(nonnull GCDAsyncSocket *)newSocket
{
    // 保存客户端的socket
    [self.dClientSockets setObject:newSocket forKey:newSocket.connectedHost];
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
    NSLog(@"%@:%d==%@:%d",newSocket.localHost,newSocket.localPort,newSocket.connectedHost,newSocket.connectedPort);
    // 添加定时器
    //    [self addTimer];
    [newSocket readDataWithTimeout:- 1 tag:0];
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err{
    for (NSString *akey in self.dClientSockets.allKeys) {
        if ([[self.dClientSockets valueForKey:akey] isEqual:sock]) {
//            PLCType type = [[ConfigurationFile shareConfigurationFile] getPlcTypeWithIP:akey];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketStatus" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",type],@"sockethost", @"disconnect",@"status",nil]];
            break;
        }
    }
    //     NSLog(@"%@==%@",sock.localHost,err);
}
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%@:%d",host,port);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",text);
    
    [sock readDataWithTimeout:- 1 tag:0];
}
@end
