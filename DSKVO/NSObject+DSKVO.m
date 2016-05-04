//
//  NSObject+kvokvo.m
//  测试项目iPhone
//
//  Created by Computer on 16/1/14.
//  Copyright © 2016年 EaiCloud. All rights reserved.
//

#import "NSObject+DSKVO.h"
#import "DSObserver.h"
#import "ObserverData.h"
#import <objc/runtime.h>
@implementation NSObject (DSKVO)

+ (void)load
{
    [self switchMethod];
}

+ (void)switchMethod
{
    SEL removeSel = @selector(removeObserver:forKeyPath:);
    SEL myRemoveSel = @selector(removeDasen:forKeyPath:);
    SEL addSel = @selector(addObserver:forKeyPath:options:context:);
    SEL myaddSel = @selector(addDasen:forKeyPath:options:context:);

    Method systemRemoveMethod = class_getClassMethod([self class],removeSel);
    Method DasenRemoveMethod = class_getClassMethod([self class], myRemoveSel);
    Method systemAddMethod = class_getClassMethod([self class],addSel);
    Method DasenAddMethod = class_getClassMethod([self class], myaddSel);

    method_exchangeImplementations(systemRemoveMethod, DasenRemoveMethod);
    method_exchangeImplementations(systemAddMethod, DasenAddMethod);
}


#pragma mark - 第一种方案，利用@try @catch
//// 交换后的方法
//- (void)removeDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath
//{
//    @try {
//        [self removeDasen:observer forKeyPath:keyPath];
//    } @catch (NSException *exception) {}
//
//}

//// 交换后的方法
//- (void)addDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
//{
//    [self addDasen:observer forKeyPath:keyPath options:options context:context];
//
//}

#pragma mark - 第二种方案，利用私有属性
//// 交换后的方法
//- (void)removeDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath
//{
//    NSMutableArray *Observers = [DSObserver sharedDSObserver];
//    ObserverData *userPathData = [self observerKeyPath:keyPath];
//    // 如果有该key值那么进行删除
//    if (userPathData) {
//        [Observers removeObject:userPathData];
//        [self removeDasen:observer forKeyPath:keyPath];
//    }
//    return;
//}
//
//// 交换后的方法
//- (void)addDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
//{
//    ObserverData *userPathData= [[ObserverData alloc]initWithObjc:self key:keyPath];
//    NSMutableArray *Observers = [DSObserver sharedDSObserver];
//
//    // 如果没有注册，那么才进行注册
//    if (![self observerKeyPath:keyPath]) {
//        [Observers addObject:userPathData];
//        [self addDasen:observer forKeyPath:keyPath options:options context:context];
//    }
//
//}
//
//// 进行检索，判断是否已经存储了该Key值
//- (ObserverData *)observerKeyPath:(NSString *)keyPath
//{
//    NSMutableArray *Observers = [DSObserver sharedDSObserver];
//    for (ObserverData *data in Observers) {
//        if ([data.objc isEqual:self] && [data.keyPath isEqualToString:keyPath]) {
//            return data;
//        }
//    }
//    return nil;
//}

#pragma mark - 第三种方案，利用私有属性
// 交换后的方法
- (void)removeDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    if ([self observerKeyPath:keyPath]) {
        [self removeDasen:observer forKeyPath:keyPath];
    }
}

// 交换后的方法
- (void)addDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    if (![self observerKeyPath:keyPath]) {
        [self addDasen:observer forKeyPath:keyPath options:options context:context];
    }
}


// 进行检索获取Key
- (BOOL)observerKeyPath:(NSString *)key
{
    id info = self.observationInfo;
    NSArray *array = [info valueForKey:@"_observances"];
    for (id objc in array) {
        id Properties = [objc valueForKeyPath:@"_property"];
        NSString *keyPath = [Properties valueForKeyPath:@"_keyPath"];
        if ([key isEqualToString:keyPath]) {
            return YES;
        }
    }
    return NO;
}





@end
