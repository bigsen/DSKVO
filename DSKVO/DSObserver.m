//
//  DSObserver.m
//  测试KVO
//
//  Created by 张大森 on 16/5/4.
//  Copyright © 2016年 zhangdasen. All rights reserved.
//

#import "DSObserver.h"

@implementation DSObserver
+ (instancetype)sharedDSObserver
{
    static id objc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        objc = [NSMutableArray array];
    });
    return objc;
}

@end
