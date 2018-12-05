//
//  KVOTestViewController.m
//  LDKVO
//
//  Created by lidi on 2018/12/4.
//  Copyright © 2018 Li. All rights reserved.
//

#import "KVOTestViewController.h"
#import "Person.h"
#import "NSObject+LDKVO.h"
@interface KVOTestViewController ()
@end

@implementation KVOTestViewController
- (void)dealloc {
    NSLog(@"KVOTestViewController dealloc");
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];

//    self.person = [[Person alloc]init];
//    self.person.name = @"tom";

    [self.person LD_addObserver:self forKeyPath:@"age"];
    [self.person LD_addObserver:self forKeyPath:@"name"];
    [self.person LD_addObserver:self forKeyPath:@"name"];

//    [self.person addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
//    [self.person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:nil];

    [self addButtons];
    
}
// 系统observeValueForKeyPath方法不会执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@,%@",object,change);
}
- (void)LD_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(void *)newValue {
    if ([keyPath isEqualToString:@"age"]) {
        int value = (int)newValue;
        NSLog(@"%@,%d",object,value);
    }else{
        NSLog(@"%@,%@",object,newValue);
    }
}

- (void)changeNameValue {
//    属性赋值
//    self.person.name = [self.person.name stringByAppendingString:@"m"];
//    self.person.age += 1;
    // 以KVC方式改变值
    [self.person setValue:@"lucy" forKey:@"name"];
    NSInteger age = self.person.age+1;
    [self.person setValue:[NSNumber numberWithInteger:age] forKey:@"age"];
}
- (void)removeLD_Observer {
//    [self.person LD_removeObserver:self forKeyPath:@"name"];
//    [self.person LD_removeObserver:self forKeyPath:@"age"];
//    [self.person LD_removeAllObserversOfKeyPath:@"age"];
    [self.person LD_removeAllObservers];
}


- (void)addButtons {
    UIButton *changeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    changeButton.frame = CGRectMake(70, 200, 100 , 40);
    [changeButton setTitle:@"改变值" forState:0];
    [changeButton addTarget:self action:@selector(changeNameValue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeButton];
    
    UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    removeButton.frame = CGRectMake(220, 200, 100 , 40);
    [removeButton setTitle:@"移除观察者" forState:0];
    [removeButton addTarget:self action:@selector(removeLD_Observer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:removeButton];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
