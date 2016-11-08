
DSKVO 拦截系统KVO监听，防止多次删除和添加
==============
# DSKVO
底层修改判断KVO，可实现防止忘记移除KVO监听后，再次移除崩溃。防止多次添加KVO监听，造成的监听混乱
# 使用方法
拖进项目中使用即可
# 核心代码
    id info = self.observationInfo;
    NSArray *array = [info valueForKey:@"_observances"];
    id Properties = [objc valueForKeyPath:@"_property"];
    NSString *keyPath = [Properties valueForKeyPath:@"_keyPath"];


#-------
![](http://upload-images.jianshu.io/upload_images/790890-e9cccd0a2885d5b3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
##### 一、使用场景
有时候我们会忘记添加多次KVO监听或者，不小心删除如果KVO监听，如果添加多次KVO监听这个时候我们就会接受到多次监听。
如果删除多次kvo程序就会造成catch，如下图
![](http://upload-images.jianshu.io/upload_images/790890-7790e88505a52fcf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)这时候我们就可以想一些方案来防止这种情况的发生。
***
##### 二、使用技术
核心 : 利用runtime实现方法交换，进行拦截add和remove进行操作。
1. 方案一 ：利用 @try   @catch
2. 方案二 ：利用 模型数组 进行存储记录
3. 方案二 ：利用 observationInfo 里私有属性

(1) 方案一（只能针对删除多次KVO的情况下）
利用 @try @catc

不得不说这种方法真是很Low，但是很简单就可以实现。
这种方法只能针对多次删除KVO的处理，原理就是try catch可以捕获异常，不让程序catch。这样就实现了防止多次删除KVO。
```
@try {
        [self.btn removeObserver:self forKeyPath:@"kkl"];
    } 
@catch (NSException *exception) {
        NSLog(@"多次删除了");
}

```
普通情况下，使用这种方法就需要每次removeObserver的时候，就加上去一个@try @catch 
有个简单的方法：给NSObject 增加一个分类，然后利用Run time 交换系统的 removeObserver方法，在里面添加 @try @catch。

runtime 就不多说了，大家自己自己查下相关资料有很多。
下面就直接上实现代码了：

***NSObject+DSKVO.m***
```
#import "NSObject+DSKVO.h"
#import <objc/runtime.h>
@implementation NSObject (DSKVO)

+ (void)load
{
    [self switchMethod];
}

// 交换后的方法
- (void)removeDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    @try {
        [self removeDasen:observer forKeyPath:keyPath];
    } @catch (NSException *exception) {}
}

+ (void)switchMethod
{
    SEL removeSel = @selector(removeObserver:forKeyPath:);
    SEL myRemoveSel = @selector(removeDasen:forKeyPath:);

    Method systemRemoveMethod = class_getClassMethod([self class],removeSel);
    Method DasenRemoveMethod = class_getClassMethod([self class], myRemoveSel);

    method_exchangeImplementations(systemRemoveMethod, DasenRemoveMethod);
}

@end
```
***
(2) 方案二
利用 模型数组 进行存储记录

**第一步**  利用交换方法，拦截到需要的东西
1，是在监听哪个对象。
2，是在监听的keyPath是什么。

**第二步** 存储思路
1，我们需要一个模型用来存储 
哪个对象执行了addObserver、监听的KeyPath是什么。
2，我们需要一个数组来存储这个模型。

**第三步** 进行存储
1，利用runtime 拦截到对象和keyPath,创建模型然后进行赋值模型相应的属性。
2，然后存储进数组中去。

**第三步** 存储之前的检索处理
1，在存储之前，为了防止多次addObserver相同的属性，这个时候我们就可以，遍历数组，取出每个一个模型，然后取出模型中的对象，首先判断对象是否一致，然后判断keypath是否一致2，对于添加KVO监听：如果不一致那么就执行利用交换后方法执行addObserver方法。

3，对于删除KVO监听:   如果一致那么我们就执行删除监听,否则不执行。

4，上代码了：
***NSObject+DSKVO.m***
```
#import "NSObject+DSKVO.h"
#import "DSObserver.h"
#import "ObserverData.h"
#import <objc/runtime.h>
@implementation NSObject (DSKVO)

+ (void)load
{
    [self switchMethod];
}

// 交换后的方法
- (void)removeDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    NSMutableArray *Observers = [DSObserver sharedDSObserver];
    ObserverData *userPathData = [self observerKeyPath:keyPath];
    // 如果有该key值那么进行删除
    if (userPathData) {
        [Observers removeObject:userPathData];
        [self removeDasen:observer forKeyPath:keyPath];
    }
 return;
}

// 交换后的方法
- (void)addDasen:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    ObserverData *userPathData= [[ObserverData alloc]initWithObjc:self key:keyPath];
    NSMutableArray *Observers = [DSObserver sharedDSObserver];

    // 如果没有注册，那么才进行注册
    if (![self observerKeyPath:keyPath]) {
        [Observers addObject:userPathData];
        [self addDasen:observer forKeyPath:keyPath options:options context:context];
    }

}

// 进行检索，判断是否已经存储了该Key值
- (ObserverData *)observerKeyPath:(NSString *)keyPath
{
    NSMutableArray *Observers = [DSObserver sharedDSObserver];
    for (ObserverData *data in Observers) {
        if ([data.objc isEqual:self] && [data.keyPath isEqualToString:keyPath]) {
                return data;
        }
    }
    return nil;
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
```
ObserverData  模型类文件有两个属性
```
@property (nonatomic, strong)id objc;
@property (nonatomic, copy)  NSString *keyPath;
```

DSObserver 类是一个单例数组
```
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
```
***
(3) 方案三
利用 observationInfo 里私有属性

**第一步** 简单介绍下observationInfo属性
1，只要是继承与NSObject的对象都有observationInfo属性.
2，observationInfo是系统通过分类给NSObject增加的属性。
3，分类文件是NSKeyValueObserving.h这个文件
4，这个属性中存储有属性的监听者，通知者，还有监听的keyPath，等等KVO相关的属性。
5，observationInfo是一个void指针，指向一个包含所有观察者的一个标识信息对象，信息包含了每个监听的观察者,注册时设定的选项等。
```
@property (nullable) void *observationInfo;
```
6，observationInfo结构 (箭头所指是我们等下需要用到的地方)
![](http://upload-images.jianshu.io/upload_images/790890-f66f2d1d99117125.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**第二步** 实现方案思路
1，通过私有属性直接拿到当前对象所监听的keyPath

2，判断keyPath有或者无来实现防止多次重复添加和删除KVO监听。

3，通过Dump Foundation.framework 的头文件，和直接xcode查看observationInfo的结构，发现有一个数组用来存储NSKeyValueObservance对象，经过测试和调试，发现这个数组存储的需要监听的对象中，监听了几个属性，如果监听两个，数组中就是2个对象。
比如这是监听两个属性状态下的数组
![](http://upload-images.jianshu.io/upload_images/790890-40dd819dfe7af302.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

4，NSKeyValueObservance属性简单说明
_observer属性：里面放的是监听属性的通知这，也就是当属性改变的时候让哪个对象执行observeValueForKeyPath的对象。
_property	里面的NSKeyValueProperty	NSKeyValueProperty存储的有keyPath,其他属性我们用不到，暂时就不说了。
![](http://upload-images.jianshu.io/upload_images/790890-0f7f9fbd30fe2896.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

5，拿出keyPath
这时候思路就有了，首先拿出_observances数组，然后遍历拿出里面_property对象里面的NSKeyValueProperty下的一个keyPath，然后进行判断需要删除或添加的keyPath是否一致，然后分别进行处理就行了。
补充：NSKeyValueProperty我当时测试直接kvc取出来的时候发现取不出来，报错，后台直接取keyPath就可以，然后就直接取keyPath了，有知道原因的可以给我说下。
![](http://upload-images.jianshu.io/upload_images/790890-0d78815110d67d7a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

6，上代码
```
#import "NSObject+DSKVO.h"
#import <objc/runtime.h>
@implementation NSObject (DSKVO)

+ (void)load
{
    [self switchMethod];
}

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
```
***
>参考文章：http://www.bkjia.com/IOSjc/993206.html
参考人员：tyh
github地址：https://github.com/DaSens/DSKVO

感谢各位阅读，有什么补充的希望大家提出来。
