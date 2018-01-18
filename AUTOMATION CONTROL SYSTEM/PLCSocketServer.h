//
//  PLCSocketServer.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/25.
//  Copyright © 2017年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "FixtureType.h"

@interface PLCSocketServer : NSObject<GCDAsyncSocketDelegate>{
    int robotCommandId;
    int conveyorCommandId;
    NSMutableDictionary *dDataIdentyByTag;
    NSString *robotIP;
    NSString *conveyorIP;
}

@property (strong, nonatomic) GCDAsyncSocket *serverSocket;
@property (strong ,nonatomic)NSMutableDictionary *dClientSockets;

+(PLCSocketServer *)shareIntance;

-(BOOL)sendCommandAndReadResult:(PLCType)location withTimeOut:(int)timeout;

@end
