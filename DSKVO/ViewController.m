//
//  ViewController.m
//  测试KVO
//
//  Created by 张大森 on 16/5/3.
//  Copyright © 2016年 zhangdasen. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()
@property (nonatomic, strong)UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    self.btn = [[UIButton alloc]init];

    [self.btn addObserver:self forKeyPath:@"tintColor" options:NSKeyValueObservingOptionNew context:nil];
    [self.btn addObserver:self forKeyPath:@"zhangdasen" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.btn removeObserver:self forKeyPath:@"tintColor"];
    [self.btn removeObserver:self forKeyPath:@"zhangdasen"];
    [self.btn removeObserver:self forKeyPath:@"tintColor"];
    [self.btn removeObserver:self forKeyPath:@"zhangdasen"];
    [self.btn removeObserver:self forKeyPath:@"tintColor"];
    [self.btn removeObserver:self forKeyPath:@"zhangdasen"];
    [self.btn removeObserver:self forKeyPath:@"tintColor"];
    [self.btn removeObserver:self forKeyPath:@"zhangdasen"];
}


@end
