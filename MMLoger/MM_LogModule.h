//
//  MM_LogModule.h
//  Weather_App
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Yrocky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

static int ddLogLevel = 0xFFFFFFFF;

typedef NS_OPTIONS(NSInteger, MM_LogModuleType) {
    MM_LogModuleNetworkInfo = 1<<10,
    MM_LogModuleNetworkError,
    
    MM_LogModuleZegoInfo,
    MM_LogModuleZegoError,
    
    MM_LogModuleCrash,
};

@protocol MM_LogModuleProtocol <NSObject>
@property (nonatomic ,copy) NSString * moduleName;
- (NSString *) formatLogWithModelType:(MM_LogModuleType)type;
@end

#define MM_LOG_MACRO(Module_Name,log_flag, fmt, ...)     \
LOG_MAYBE(LOG_ASYNC_INFO,LOG_LEVEL_DEF, log_flag, Module_Name,__PRETTY_FUNCTION__, fmt, ##__VA_ARGS__)\

#define MM_LOG_MODULE(Module_Name,log_flag,fmt,...)\
do {MM_LOG_MACRO(Module_Name,log_flag,@"%s #%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);} while(0)

// network
#define NSLogNetworkInfo(fmt, ...)    \
MM_LOG_MODULE(MM_LogModuleNetworkInfo, LOG_FLAG_INFO,fmt, ##__VA_ARGS__)

#define NSLogNetworkError(fmt, ...)    \
MM_LOG_MODULE(MM_LogModuleNetworkError, LOG_FLAG_ERROR, fmt, ##__VA_ARGS__)

// zego
#define NSLogZegoInfo(fmt, ...)    \
MM_LOG_MODULE(MM_LogModuleZegoInfo, LOG_FLAG_INFO, fmt, ##__VA_ARGS__)

#define NSLogZegoError(fmt, ...)    \
MM_LOG_MODULE(MM_LogModuleZegoError, LOG_FLAG_ERROR, fmt, ##__VA_ARGS__)

@interface MM_LogModule : NSObject<MM_LogModuleProtocol>

@property (nonatomic ,copy) NSString * moduleName;

- (void) formatLogWithModuleTypeCallback:(NSString *(^)(MM_LogModuleType type))cb;
@end
