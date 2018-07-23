//
//  MM_LogFileManager.m
//  Weather_App
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Yrocky. All rights reserved.
//

#import "MM_LogFileManager.h"
#import <libkern/OSAtomic.h>

@interface MM_LogFileManager ()

@property (nonatomic, copy ,readwrite) NSString *moduleNmae;
@end

@implementation MM_LogFileManager

- (instancetype)initWithLogsModule:(id<MM_LogModuleProtocol>)module{
    
    self = [super initWithLogsDirectory:nil];
    if (self) {
        self.moduleNmae = module.moduleName;
    }
    return self;
}

#pragma mark - Override methods

- (BOOL)isLogFile:(NSString *)fileName{
    
    BOOL hasModuleNmae = [fileName hasPrefix:self.moduleNmae];
    BOOL hasProperSuffix = [fileName hasSuffix:@".log"];
    
    return hasModuleNmae && hasProperSuffix;
}

- (NSString *)newLogFileName {

    //重写文件名称
    NSDateFormatter *dateFormatter = [self logFileDateFormatter];
    NSString *formattedDate = [dateFormatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%@ %@.log", self.moduleNmae, formattedDate];
}

- (NSDateFormatter *)logFileDateFormatter {
    NSMutableDictionary *dictionary = [[NSThread currentThread]
                                       threadDictionary];
    NSString *dateFormat = @"yyyy'-'MM'-'dd' 'HH'-'mm'";
    NSString *key = [NSString stringWithFormat:@"logFileDateFormatter.%@", dateFormat];
    NSDateFormatter *dateFormatter = dictionary[key];

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:dateFormat];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        dictionary[key] = dateFormatter;
    }

    return dateFormatter;
}
@end

@interface MM_LogFilterLogFormatter ()

@property (nonatomic ,strong) id<MM_LogModuleProtocol> module;
@end

@implementation MM_LogFilterLogFormatter

- (instancetype)initWithLogsModule:(id<MM_LogModuleProtocol>)module{
    self = [super init];
    if (self) {
        self.module = module;
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel = nil;
    if (self.module) {
        logLevel = [self.module formatLogWithModelType:logMessage->logContext];
    }
    if (!logLevel) {
        return nil;
    }
    
    NSString *dateAndTime = [self stringFromDate:(logMessage->timestamp)];
    
    NSString *formatStr = [NSString stringWithFormat:@"%@%@ %@",
                           logLevel,dateAndTime, logMessage->logMsg];
    return formatStr;
}


- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
