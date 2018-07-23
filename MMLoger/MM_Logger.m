//
//  MM_Logger.m
//  MMLoger
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Rocky Young. All rights reserved.
//

#import "MM_Logger.h"
#import "MM_LogFileManager.h"
#import "CocoaLumberjack/DDLog.h"
#import "CocoaLumberjack/DDFileLogger.h"
#import "CocoaLumberjack/DDTTYLogger.h"

@interface MM_Logger() <DDLogFormatter>
@property (nonatomic, assign) MMLogLevel logLevel;
@end

#pragma mark - implement

@implementation MM_Logger

+ (instancetype)sharedInstance
{
    static MM_Logger *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[MM_Logger alloc] init];
    });
    return _instance;
}

+ (void)startWithLogLevel:(MMLogLevel)logLevel
{
    [self sharedInstance];
    [[self sharedInstance] setLogLevel:logLevel];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
#if DEBUG
        // sends log statements to Xcode console - if available
        [[DDTTYLogger sharedInstance] setLogFormatter:self];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
        // 所有日志文件输出
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24 * 7; // 7 * 24 hour rolling
        fileLogger.maximumFileSize = 10 * 1024 * 1024;           // 文件达到 10MB 回滚
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [fileLogger setLogFormatter:self];
        [DDLog addLogger:fileLogger];
    }
    return self;
}

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

+ (NSString *)logsDirectoryPath{
    
    // 这是DDLog源码中设置logs文件夹的位置，直接copy过来的
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];

    return logsDirectory;
}

+ (void) addCrashLog:(BOOL)add{
    
    if (add) {
        MM_LogModule * networkModule = [[MM_LogModule alloc] init];
        networkModule.moduleName = @"Crash";
        [networkModule formatLogWithModuleTypeCallback:^NSString *(MM_LogModuleType type) {
            NSString * logLevel = nil;
            switch (type){
                case MM_LogModuleCrash:
                    logLevel = @"[Crash Info]  > ";
                    break;
                default:
                    return nil;
            }
            return logLevel;
        }];
        [MM_Logger addLogModule:networkModule];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel = nil;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_ERROR:
            logLevel = @"[ERROR] > ";
            break;
        case LOG_FLAG_WARN:
            logLevel = @"[WARN]  > ";
            break;
        case LOG_FLAG_INFO:
            logLevel = @"[INFO]  > ";
            break;
        case LOG_FLAG_DEBUG:
            logLevel = @"[DEBUG] > ";
            break;
        default:
            logLevel = @"[VBOSE] > ";
            break;
    }
    
    NSDateFormatter * dateFor = [[NSDateFormatter alloc] init];
    [dateFor setDateFormat:@"yyyy'-'MM'-'dd' 'HH'-'mm'"];
    NSString *dateAndTime = [dateFor stringFromDate:(logMessage->timestamp)];
    
    NSString *formatStr = [NSString stringWithFormat:@"%@%@ %@",
                           logLevel,dateAndTime, logMessage->logMsg];
    return formatStr;
}

- (void)setLogLevel:(MMLogLevel)logLevel
{
    _logLevel = logLevel;
    switch (_logLevel) {
        case MMLogLevelDEBUG:
            ddLogLevel = LOG_LEVEL_DEBUG;
            break;
        case MMLogLevelINFO:
            ddLogLevel = LOG_LEVEL_INFO;
            break;
        case MMLogLevelWARN:
            ddLogLevel = LOG_LEVEL_WARN;
            break;
        case MMLogLevelERROR:
            ddLogLevel = LOG_LEVEL_ERROR;
            break;
        case MMLogLevelOFF:
            ddLogLevel = LOG_LEVEL_OFF;
            break;
        default:
            break;
    }
}

//! 记录日志(有格式)
- (void)logLevel:(MMLogLevel)level format:(NSString *)format, ...
{
    if (format)
    {
        va_list args;
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        [self logLevel:level message:message];
    }
}

//! 记录日志(无格式)
- (void)logLevel:(MMLogLevel)level message:(NSString *)message
{
    if (message.length > 0)
    {
        switch (level)
        {
            case MMLogLevelERROR:
                DDLogError(@"%@", message);
                break;
            case MMLogLevelWARN:
                DDLogWarn(@"%@", message);
                break;
            case MMLogLevelINFO:
                DDLogInfo(@"%@", message);
                break;
            case MMLogLevelDEBUG:
                DDLogDebug(@"%@", message);
                break;
            default:
                DDLogVerbose(@"%@", message);
                break;
        }
    }
}

@end

void mm_uncaughtExceptionHandler(NSException *exception){
    
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"reason：%@\nname：%@\nstack：%@",name, reason, stackArray];
    
    //保存到本地
    NSString * crashLogPath = [[MM_Logger logsDirectoryPath] stringByAppendingString:@"/crash.log"];
    [exceptionInfo writeToFile:crashLogPath
                    atomically:YES
                      encoding:NSUTF8StringEncoding error:nil];
}

