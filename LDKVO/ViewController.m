//
//  ViewController.m
//  LDKVO
//
//  Created by lidi on 2018/12/3.
//  Copyright © 2018 Li. All rights reserved.
//

#import "ViewController.h"
#import "KVOTestViewController.h"
#import "Person.h"
#import "NSObject+LDKVO.h"

@interface ViewController ()
@property(nonatomic,strong)Person *person;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];

    UIButton *pushButton = [UIButton buttonWithType:UIButtonTypeSystem];
    pushButton.frame = CGRectMake(0, 0, 100 , 40);
    pushButton.center = self.view.center;
    [pushButton setTitle:@"push" forState:0];
    [pushButton addTarget:self action:@selector(pushKVOViewController) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pushButton];
    
    
    self.person = [[Person alloc]init];
    self.person.name = @"tom";
    self.person.age = 18;
    [self.person LD_addObserver:self forKeyPath:@"age"];

}

- (void)pushKVOViewController{
    KVOTestViewController *kvoTest = [[KVOTestViewController alloc]init];

    kvoTest.person = self.person;
    [self.navigationController pushViewController:kvoTest animated:YES];
}
- (void)LD_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(void *)newValue {
    int value = (int)newValue;
    NSLog(@"%@-%d",object,value);
}
@end
