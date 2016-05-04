//
//  ObserverData.h
//  测试KVO
//
//  Created by 张大森 on 16/5/4.
//  Copyright © 2016年 zhangdasen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObserverData : NSObject
@property (nonatomic, strong)id objc;
@property (nonatomic, copy)  NSString *keyPath;
- (instancetype)initWithObjc:(id)objc key:(NSString *)key;

@end
