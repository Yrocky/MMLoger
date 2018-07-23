//
//  MM_Logger.h
//  MMLoger
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Rocky Young. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MM_LogModule.h"

typedef NS_ENUM(UInt8, MMLogLevel) {
    MMLogLevelDEBUG         = 1,// 打印所有
    MMLogLevelINFO          = 2,// 仅仅打印info、error、warn
    MMLogLevelWARN          = 3,// 打印warn、error
    MMLogLevelERROR         = 4,// 打印error
    MMLogLevelOFF           = 5,
};

void mm_uncaughtExceptionHandler(NSException *exception);

#define MM_LOGGER_MACRO(level, fmt, ...)     [[MM_Logger sharedInstance] logLevel:level format:(fmt), ##__VA_ARGS__]
#define MM_LOG_PRETTY(level, fmt, ...)    \
do {MM_LOGGER_MACRO(level, @"%s #%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);} while(0)

#define MMLogError(frmt, ...)   MM_LOG_PRETTY(MMLogLevelERROR, frmt, ##__VA_ARGS__)
#define MMLogWarn(frmt, ...)    MM_LOG_PRETTY(MMLogLevelWARN,  frmt, ##__VA_ARGS__)
#define MMLogInfo(frmt, ...)    MM_LOG_PRETTY(MMLogLevelINFO,  frmt, ##__VA_ARGS__)
#define MMLogDebug(frmt, ...)   MM_LOG_PRETTY(MMLogLevelDEBUG, frmt, ##__VA_ARGS__)
#define DLog(frmt, ...) MM_LOG_PRETTY(MMLogLevelDEBUG, frmt, ##__VA_ARGS__)

/**
 * 对log日志的管理，里面有对控制台的日志输出、文件输出两部分
 * 其中控制台的日志输出已经通过DEBUG来控制，仅仅在开发模式下打印日志
 *
 * 文件输出存储分为全局日志存储、模块存储
 * 全局日志存储，可以通过设置 `-startWithLogLevel:`，方法来决定哪些日志信息需要保存在文件中
 * 模块存储，可以为不同的功能模块添加专门的日志存储，**不可以控制日志级别**
 */
@interface MM_Logger : NSObject

+ (instancetype)sharedInstance;

// 设置全局日志存储的级别，参考枚举的解释，对添加的模块无效
+ (void) startWithLogLevel:(MMLogLevel)logLevel;

// TODO: 添加crash的时候的堆栈信息到本地
+ (void) addCrashLog:(BOOL)add;

// 添加特定模块的log文件
+ (void) addLogModule:(id<MM_LogModuleProtocol>)module;

- (void)logLevel:(MMLogLevel)level format:(NSString *)format, ...;
- (void)logLevel:(MMLogLevel)level message:(NSString *)message;

// 获取logs文件夹的位置
+ (NSString *) logsDirectoryPath;

@end
