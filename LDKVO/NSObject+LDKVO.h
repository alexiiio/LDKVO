//
//  NSObject+LDKVO.h
//  LDKVO
//
//  Created by lidi on 2018/12/3.
//  Copyright © 2018 Li. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NSObject (LDKVO)


/**
 添加观察者

 @param observer 观察者对象
 @param keyPath 要观察的属性
 */
- (void)LD_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
/**
移除观察者，解除循环引用

 @param observer 观察者对象
 @param keyPath 被观察的属性
 */
- (void)LD_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
/**
移除指定keyPath的所有观察者

 @param keyPath 被观察的属性
 */
- (void)LD_removeAllObserversOfKeyPath:(NSString *)keyPath;
/**
移除所有观察者，并恢复被观察对象为原类型

 */
- (void)LD_removeAllObservers;
/**
当被观察对象的指定键路径的值发生变化时，通知观察对象。
 
 @param keyPath 被观察属性名
 @param object 被观察对象
 @param newValue 被观察属性新值，统一转为void *，使用时需要转回原类型。
 */
- (void)LD_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(void *)newValue ;

@end


