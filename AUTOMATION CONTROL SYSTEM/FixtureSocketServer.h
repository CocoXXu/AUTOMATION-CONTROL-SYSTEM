//
//  FixtureSocketServer.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/25.
//  Copyright © 2017年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "CocoaAsyncSocket.framework/Headers/CocoaAsyncSocket.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface FixtureSocketServer : NSObject<GCDAsyncSocketDelegate>

@property (strong, nonatomic) GCDAsyncSocket *serverSocket;
@property (strong ,nonatomic)NSMutableDictionary *dClientSockets;

+(FixtureSocketServer *)shareIntance;

@end
