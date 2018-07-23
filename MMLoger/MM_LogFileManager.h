//
//  MM_LogFileManager.h
//  Weather_App
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Yrocky. All rights reserved.
//
#import "CocoaLumberjack/DDLog.h"
#import "CocoaLumberjack/DDFileLogger.h"
#import "CocoaLumberjack/DDContextFilterLogFormatter.h"
#import "MM_LogModule.h"

@interface MM_LogFileManager : DDLogFileManagerDefault

- (instancetype)initWithLogsModule:(id<MM_LogModuleProtocol>)module;
@end

@interface MM_LogFilterLogFormatter : NSObject<DDLogFormatter>{
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

- (instancetype)initWithLogsModule:(id<MM_LogModuleProtocol>)module;
@end
