//
//  FixtureType.h
//  AUTOMATION CONTROL SYSTEM
//
//  Created by apple on 17/12/22.
//  Copyright © 2017年 coco. All rights reserved.
//

#ifndef FixtureType_h
#define FixtureType_h
typedef enum {
    REGISTER=0,//注册
    IDLE,
    TEST,
    PASS,
    FAIL,
    OFFLINE,
    DISABLE
} FitureStaus;

#define insertNG 0
#define insertOK 1
#define insertRE 2

typedef enum {
    conveyor = 0,
    robot,
    fixture1 = 2,
    fixture2,
    fixture3,
    fixture4,
    fixture5,
    fixture6,
    fixture7,
    fixture8 = 9,
    undefine
}PLCType;

#endif /* FixtureType_h */
