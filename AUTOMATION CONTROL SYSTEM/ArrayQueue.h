//
//  ArrayQueue.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 18/1/9.
//  Copyright © 2018年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArrayQueue : NSObject{
    NSMutableArray* m_array;
}

+(ArrayQueue *)shareInstance;
- (void)enqueue:(id)anObject;
- (id)dequeue;
-(void)clear;
@property (nonatomic, readonly) int count;  
@end
