//
//  NSObject+LDKVO.m
//  LDKVO
//
//  Created by lidi on 2018/12/3.
//  Copyright © 2018 Li. All rights reserved.
//

#import "NSObject+LDKVO.h"
#import <objc/message.h>

static const char *kLDKVOObserverDictionary = "kLDKVOObserverDictionary";
@implementation NSObject (LDKVO)
- (void)LD_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    
//    动态生成一个类
    //    拼接类名
    NSString *oldClass = NSStringFromClass(object_getClass(self));
    // 如果已经是一个KVO类，就不需要修改isa指针
    if (![oldClass hasPrefix:@"LDKVO_"]) {
        NSString *newClass = [NSString stringWithFormat:@"LDKVO_%@",oldClass];
        //    创建类，先判断是否已注册该类
        Class kvoClass = objc_lookUpClass(newClass.UTF8String);
        if (!kvoClass) {
            //  第一个参数：生成类的父类，第二个参数：类名
            kvoClass = objc_allocateClassPair(object_getClass(self), newClass.UTF8String, 0);
            //  注册类
            objc_registerClassPair(kvoClass);
        }
        //    修改被观察者的isa指针
        object_setClass(self, kvoClass);
    }

 
    //    添加set方法，相当于重写父类的set方法。 方法名是 setName: 这种格式
    SEL setMethod = NSSelectorFromString([self getSetterMethodNameFromKeyPath:keyPath]);
    // (IMP)setterIMP 强转成函数指针。"v@:@"：v代表void，后面代表参数，@表示对象类型，: 代表SEL类型。
    Class myClass = object_getClass(self); // 已经是一个KVO类
    // 获取父类的setter Method
    Method superSetter = class_getInstanceMethod([self superclass], setMethod);
//  获取父类setter方法的 类型编码（因为属性有id类型和基本数据类型，不能写死）
    const char *setterTypes = method_getTypeEncoding(superSetter);
    class_addMethod(myClass, setMethod, (IMP)setterIMP, setterTypes);
//    class_addMethod(myClass, setMethod, (IMP)setterIMP, "v@:@");
  
    
    // 把监听的keyPath跟对象关联保存
    // 如果 Key 不是同一种类型，会取不到值（setMethod 和 _cmd都是SEL类型）
    objc_setAssociatedObject(self, setMethod, keyPath, OBJC_ASSOCIATION_COPY);
    
    // 把观察者存到一个字典里，关联到被观察者对象
//    观察同一个属性的观察者们放到一个数组里，然后以属性名为key存到字典里
    NSMutableDictionary *observerDictionary = objc_getAssociatedObject(self, kLDKVOObserverDictionary);
    NSMutableArray *currentKeyObservers;
    BOOL needAddObserver = YES;
    if (!observerDictionary) {
        observerDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
        currentKeyObservers = [NSMutableArray arrayWithCapacity:10];
        [observerDictionary setValue:currentKeyObservers forKey:keyPath];
    }else{
        if ([[observerDictionary allKeys] containsObject:keyPath]) {
            currentKeyObservers = [observerDictionary valueForKey:keyPath];
            // 当前属性有观察者，且观察者数组包含要添加的观察者是，不再重复添加
            if ([currentKeyObservers containsObject:observer]) {
                needAddObserver = NO;
                NSLog(@"%s 不要重复添加观察者！observer: %@, Key: %@",__FUNCTION__,observer,keyPath);
            }
        }else{
            currentKeyObservers = [NSMutableArray arrayWithCapacity:10];
            [observerDictionary setValue:currentKeyObservers forKey:keyPath];
        }
    }
    if (needAddObserver) {
        [currentKeyObservers addObject:observer];
    }
     // 添加关联会使观察者与被观察者之间形成循环引用，需要在removeObserver时破除循环
    objc_setAssociatedObject(self, kLDKVOObserverDictionary, observerDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
/* void * 是一个指针，可以指向任意类型。而id是指向任意OC对象类型。
    如果使用id，当接收到一个基本数据类型的参数时程序会崩溃
    可以把基本类型赋值给void *，使用时再转回原类型
 */
void setterIMP(id self,SEL _cmd,void *newValue){
//    [self setValue:newValue forKey:key]; // 会调用setter方法，造成死循环
    //    调用父类的set方法
    struct objc_super sClass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    // 需要传一个 struct objc_super * 类型的结构体
    objc_msgSendSuper(&sClass, _cmd, newValue);
    
    // 给该属性的观察者们发消息
    
    // 取出关联的 keyPath，即被观察的属性名
    NSString *key = objc_getAssociatedObject(self, _cmd);
    // 获取所有的观察者
    NSMutableDictionary *observerDictionary = objc_getAssociatedObject(self, kLDKVOObserverDictionary);
    NSMutableArray *currentKeyObservers = [observerDictionary valueForKey:key];
    for (NSObject *observer in currentKeyObservers) {
        if ([observer respondsToSelector:@selector(LD_observeValueForKeyPath:ofObject:change:)]) {
            objc_msgSend(observer, @selector(LD_observeValueForKeyPath:ofObject:change:),key,self,newValue);
        }
    }
}

//  移除观察者
- (void)LD_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
//  移除当前属性观察者，清除关联，解除循环引用
    NSMutableDictionary *observerDictionary = objc_getAssociatedObject(self, kLDKVOObserverDictionary);
    if (observerDictionary && [[observerDictionary allKeys] containsObject:keyPath]) {
        NSMutableArray *currentKeyObservers = [observerDictionary valueForKey:keyPath];
        if ([currentKeyObservers containsObject:observer]) {
            NSLog(@"%s 准备移除%@属性的观察者！observer:%@",__FUNCTION__,keyPath,observer);
            [currentKeyObservers removeObject:observer]; // 从数组移除当前观察者
            NSLog(@"%s 已经移除%@属性的观察者！",__FUNCTION__,keyPath);
            if (currentKeyObservers.count<1) {
                // 如果数组为空，说明该属性已经没有观察者了，移除该键值对
                [observerDictionary removeObjectForKey:keyPath];
                //    传入nil来清除关联
                objc_setAssociatedObject(self, NSSelectorFromString([self getSetterMethodNameFromKeyPath:keyPath]), nil, OBJC_ASSOCIATION_COPY);
                Class kvoClass = object_getClass(self);
                if ([observerDictionary allKeys].count<1) {
                    // 如果self不再有观察者，取消关联，恢复被观察者isa指针，最后销毁类
                    objc_setAssociatedObject(self, kLDKVOObserverDictionary, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    object_setClass(self, [self superclass]);
                    objc_disposeClassPair(kvoClass);  // 销毁类
                    NSLog(@"%s 该类没有其他观察者，执行销毁",__FUNCTION__);
                }
            }
        }else{
            NSLog(@"%s 没有检测到%@的观察者！",__FUNCTION__,keyPath);
        }
    }else{
        NSLog(@"%s 没有检测到%@的观察者！",__FUNCTION__,keyPath);
    }
}
- (void)LD_removeAllObserversOfKeyPath:(NSString *)keyPath {
    NSMutableDictionary *observerDictionary = objc_getAssociatedObject(self, kLDKVOObserverDictionary);
    if (observerDictionary && [[observerDictionary allKeys] containsObject:keyPath]){
        NSMutableArray *currentKeyObservers = [observerDictionary valueForKey:keyPath];
        if (currentKeyObservers.count>0) {
            NSLog(@"%s 准备移除%@属性的观察者！",__FUNCTION__,keyPath);
            [currentKeyObservers removeAllObjects];
            [observerDictionary removeObjectForKey:keyPath];
            objc_setAssociatedObject(self, NSSelectorFromString([self getSetterMethodNameFromKeyPath:keyPath]), nil, OBJC_ASSOCIATION_COPY);
            NSLog(@"%s 已经移除%@属性的所有观察者！",__FUNCTION__,keyPath);
            Class kvoClass = object_getClass(self);
            if ([observerDictionary allKeys].count<1) {
                objc_setAssociatedObject(self, kLDKVOObserverDictionary, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                object_setClass(self, [self superclass]);
                objc_disposeClassPair(kvoClass);
                NSLog(@"%s 该类没有其他观察者，执行销毁",__FUNCTION__);
            }
        }else{
            NSLog(@"%s 没有检测到%@的观察者！",__FUNCTION__,keyPath);
        }
    }else{
        NSLog(@"%s 没有检测到%@的观察者！",__FUNCTION__,keyPath);
    }
}
- (void)LD_removeAllObservers {
    NSMutableDictionary *observerDictionary = objc_getAssociatedObject(self, kLDKVOObserverDictionary);
    if (observerDictionary){
        [observerDictionary removeAllObjects];
        objc_setAssociatedObject(self, kLDKVOObserverDictionary, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        Class kvoClass = object_getClass(self);
        object_setClass(self, [self superclass]);
        objc_disposeClassPair(kvoClass);
        NSLog(@"%s 已经移除所有观察者！执行销毁",__FUNCTION__);
    }else{
        NSLog(@"%s 没有检测到观察者！",__FUNCTION__);
    }
}
/**
 生成 setter 方法名，类似 setName:
 */
- (NSString *)getSetterMethodNameFromKeyPath:(NSString *)keyPath {
    NSRange firstRange = NSMakeRange(0, 1);
    NSString *firstLetter = [keyPath substringWithRange:firstRange];
    NSString *upperKey = [keyPath stringByReplacingCharactersInRange:firstRange withString:firstLetter.uppercaseString];
    NSString *setMethodName = [NSString stringWithFormat:@"set%@:",upperKey]; // 一定不能忘了 :
    return setMethodName;
}
//// 重写该方法，会关闭系统KVO执行
//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    return NO;
//}
@end
