> Create youself log system.

## Cocoa Lumberjack

基于[Cocoa Lumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)构建一个log系统，支持不同模块的日志输出以及存储。

框架本身支持有ASL、TTY以及File三种日志方式，他们的作用分别为：

* 将日志发送到Apple System Logger，这样方便在系统自带的Console软件中查看具体信息
* 直接在Xcode的日志控制台中打印
* 将日志保存在文件中

这里没有使用ASL的方式，仅仅是在框架提供的File上进行的功能实现。



## File logger

框架的结构也比较简单，当有日志要输出的时候会去遍历所有的logger，根据不同logger内部的逻辑来决定日志如何处理，具体内容可以去主页看源码。在框架中要添加一个日志文件存储需要编写以下的代码：

```objective-c
// 创建准守 <DDLogFileManager> 协议的fileManager，这里使用的是框架提供的default file manager类
id<DDLogFileManager> logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:@"/Some/Path"];
logFileManager.maximumNumberOfLogFiles = 5; // 可以回滚的最大文件个数

// 创建DDFileLogger对象
DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
fileLogger.rollingFrequency = 24*60*60; // 日志文件回滚时长

// 将fileLogger添加到框架中
[DDLog addLogger:fileLogger withLevel:DDLogLevelInfo];
```

一个问题是，这样添加的日志存储文件，不能够进行模块的划分，比如对于网络请求模块，希望所有的日志信息在一个单独的文件存储。一个做法自定义日志文件存储位置，处理日志相关逻辑，这里使用的是`DDLogMessage`中的`logContext `属性来完成的。在默认的DDLogMessage是用来表示一条日志信息的类，默认的logContext 属性都是0，在框架中用到较多的是`logLevel `和`logFlag`这两个字段，通过logContext就可以完成不同模块的日志存储功能。



## Module

这里要完成模块日志的需求，需要实现两个类：

* MM_LogFileManager : DDLogFileManagerDefault
* MM_LogFilterLogFormatter : NSObject\<DDLogFormatter\>

他们的作用分别是：用来决定日志文件的存储策略、日志的文本格式。具体的内部实现可以看对应的文件，接下来还抽象出来了一个`MM_LogModuleProtocol `协议，用来约定模块的名称、对应日志级别的展示：

```objective-c
@protocol MM_LogModuleProtocol <NSObject>
@property (nonatomic ,copy) NSString * moduleName;
- (NSString *) formatLogWithModelType:(MM_LogModuleType)type;
@end
```

有了这些，就可以完成不同模块日志的添加了，一个例子如下：

```objective-c
MM_LogModule * networkModule = [[MM_LogModule alloc] init];
networkModule.moduleName = @"Network";
[networkModule formatLogWithModuleTypeCallback:^NSString *(MM_LogModuleType type) {
    NSString * logLevel = nil;
    switch (type){
        case MM_LogModuleNetworkInfo:
            logLevel = @"[Network Info]  > ";
            break;
        case MM_LogModuleNetworkError:
            logLevel = @"[Network Error] > ";
            break;
        default:
            return nil;
    }
    return logLevel;
}];
[MM_Logger addLogModule:networkModule];
```

而`+addLogModule:`内部就是上面添加logger的模板代码：

```objective-c
+ (void) addLogModule:(id<MM_LogModuleProtocol>)module{
    
    // 模块日志文件输出
    MM_LogFileManager *moduleLogFileManager = [[MM_LogFileManager alloc] initWithLogsModule:module];
    
    DDFileLogger *modulefileLogger = [[DDFileLogger alloc] initWithLogFileManager:moduleLogFileManager];
    modulefileLogger.rollingFrequency = 60 * 60 * 24 * 7; // 7 * 24 hour rolling  * 60 * 24 * 7
    modulefileLogger.maximumFileSize = 5 * 1024 * 1024;           // 文件达到 5MB 回滚
    modulefileLogger.logFileManager.maximumNumberOfLogFiles = 5;  // 最多 5 个日志文件
    
    MM_LogFilterLogFormatter * defa = [[MM_LogFilterLogFormatter alloc] initWithLogsModule:module];
    [modulefileLogger setLogFormatter:defa];
    [DDLog addLogger:modulefileLogger];
}
```



## 宏

添加不同的模块之后，提供了便捷的宏定义来简化输入，其实就是模仿框架中的便捷宏进行实现的：

```objective-c
#define MM_LOG_MACRO(Module_Name,log_flag, fmt, ...)     \
LOG_MAYBE(LOG_ASYNC_INFO,LOG_LEVEL_DEF, log_flag, Module_Name,__PRETTY_FUNCTION__, fmt, ##__VA_ARGS__)\

#define MM_LOG_MODULE(Module_Name,log_flag,fmt,...)\
do {MM_LOG_MACRO(Module_Name,log_flag,@"%s #%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);} while(0)

// network
#define NSLogNetworkInfo(fmt, ...)    \
MM_LOG_MODULE(MM_LogModuleNetworkInfo, LOG_FLAG_INFO,fmt, ##__VA_ARGS__)

#define NSLogNetworkError(fmt, ...)    \
MM_LOG_MODULE(MM_LogModuleNetworkError, LOG_FLAG_ERROR, fmt, ##__VA_ARGS__)
```

现在要在network模块中进行打印、保存日志就可以直接这样：

```objective-c
NSLogNetworkError(@"this is an network error");
NSLogNetworkInfo(@"this is a network info");
```



## Tests

工程中有对一些用例进行单元测试，具体可以参考`MMLogerTests`文件。

