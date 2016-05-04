//
//  ObserverData.m
//  测试KVO
//
//  Created by 张大森 on 16/5/4.
//  Copyright © 2016年 zhangdasen. All rights reserved.
//

#import "ObserverData.h"

@implementation ObserverData
- (instancetype)initWithObjc:(id)objc key:(NSString *)key
{
    if (self = [super init]) {
        self.objc = objc;
        self.keyPath = key;
    }
    return self;
}
@end
