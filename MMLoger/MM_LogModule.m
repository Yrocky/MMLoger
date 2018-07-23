//
//  MM_LogModule.m
//  Weather_App
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Yrocky. All rights reserved.
//

#import "MM_LogModule.h"
#import "CocoaLumberjack/DDFileLogger.h"
#import "CocoaLumberjack/DDTTYLogger.h"

@interface MM_LogModule ()

@property (copy, nonatomic) NSString *(^bAdapter)(MM_LogModuleType type);
@end
@implementation MM_LogModule

- (void) formatLogWithModuleTypeCallback:(NSString *(^)(MM_LogModuleType type))cb{
    self.bAdapter = cb;
}

- (NSString *)formatLogWithModelType:(MM_LogModuleType)type{
    
    NSString * logLevel = nil;
    if (self.bAdapter) {
        logLevel = self.bAdapter(type);
    }
    return logLevel;
}

@end
