//
//  MMLogerTests.m
//  MMLogerTests
//
//  Created by Rocky Young on 2018/7/22.
//  Copyright © 2018年 Rocky Young. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MM_Logger.h"

@interface MMLogerTests : XCTestCase

@end

@implementation MMLogerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [MM_Logger startWithLogLevel:MMLogLevelDEBUG];
    NSSetUncaughtExceptionHandler(&mm_uncaughtExceptionHandler);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testCrash{
//    [self performSelector:@selector(unknowMethod)];
}

- (void) testMMLogger{
    MMLogError(@"error...");
    MMLogInfo(@"info...");
    MMLogWarn(@"warn...");
    MMLogDebug(@"debug...");
}

- (void) testOFFMMLogger{
    
    [MM_Logger startWithLogLevel:MMLogLevelOFF];
    [self testMMLogger];
}

- (void) testDEBUGMMLogger{
    [MM_Logger startWithLogLevel:MMLogLevelDEBUG];
    [self testMMLogger];
}

- (void) testERRORMMLogger{
    [MM_Logger startWithLogLevel:MMLogLevelERROR];
    [self testMMLogger];
}

- (void) testWARNMMLogger{
    [MM_Logger startWithLogLevel:MMLogLevelWARN];
    [self testMMLogger];
}

- (void) testINFOMMLogger{
    [MM_Logger startWithLogLevel:MMLogLevelINFO];
    [self testMMLogger];
}

- (void) testPath{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"docPath:%@",docPath);
}

- (void)testNetworkModule{
    
    // 添加网络模块
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

    NSLogNetworkError(@"this is an network error");
    NSLogNetworkInfo(@"this is a network info");
}

- (void) testZegoModule{
    
    // 添加zego模块
    MM_LogModule * zegoModule = [[MM_LogModule alloc] init];
    zegoModule.moduleName = @"Zego";
    [zegoModule formatLogWithModuleTypeCallback:^NSString *(MM_LogModuleType type) {
        NSString * logLevel = nil;
        switch (type){
            case MM_LogModuleZegoInfo:
                logLevel = @"[Zego Info]  > ";
                break;
            case MM_LogModuleZegoError:
                logLevel = @"[Zego Error] > ";
                break;
            default:
                return nil;
        }
        return logLevel;
    }];
    [MM_Logger addLogModule:zegoModule];
    
    NSLogZegoInfo(@"this is a zego info");
    NSLogZegoError(@"this is an zego error");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
