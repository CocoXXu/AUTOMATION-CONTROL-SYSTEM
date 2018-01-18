//
//  ArrayQueue.m
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 18/1/9.
//  Copyright © 2018年 coco. All rights reserved.
//

#import "ArrayQueue.h"

static ArrayQueue *shareInstance = NULL;

@implementation ArrayQueue
@synthesize count;

+(ArrayQueue *)shareInstance{
    dispatch_once_t once;
    dispatch_once(&once, ^{
        shareInstance = [[ArrayQueue alloc] init];
    });
    return shareInstance;
}
- (id)init
{
    if( self=[super init] )
    {
        m_array = [[NSMutableArray alloc] init];
        count = 0;
    }
    return self;
}
//读取数据
- (void)enqueue:(id)anObject
{
    @synchronized (self){
        [m_array addObject:anObject];
        count = m_array.count;
    }
}

- (id)dequeue
{
    id obj = nil;
    @synchronized (self){
        if(m_array.count > 0)
        {
            obj = [m_array objectAtIndex:0];
            [m_array removeObjectAtIndex:0];
            count = m_array.count;
        }
    }
    return obj;
}
- (void)clear
{
    @synchronized (self){
        [m_array removeAllObjects];
        count = 0;
    }
    
}
@end
