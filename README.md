# LDKVO
使用runtime仿写系统KVO实现

除了一些基本的功能，主要解决了两个问题。

1. 一对多关系。即一个观察者可以监听多个对象的不同属性，一个属性也可以被多个观察者对象监听。
2. 可以观察任意类型。OC对象类型和基本数据类型都可以。使用的时候注意下类型转换就好了

做了逻辑判断，重复添加或移除观察者都不会有问题。

自己实现KVO主要是用来理解KVO的实现原理，以及学习使用runtime机制。如果实际项目使用KVO，可以看下Facebook的[KVOController](https://github.com/facebook/KVOController)。
