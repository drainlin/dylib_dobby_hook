//
//  constant.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "HackProtocol.h"

@implementation Constant

static void __attribute__ ((constructor)) initialize(void){
    NSLog(@"constant init");
}


+ (BOOL)isDebuggerAttached {
    BOOL isDebugging = NO;
        // 获取当前进程的信息
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        // 获取进程的环境变量
        NSDictionary *environment = [processInfo environment];
        // 检查环境变量中是否有调试器相关的标志
        if (environment != nil) {
            // 根据环境变量中是否包含特定的调试器标志来判断是否处于调试模式
            if (environment[@"DYLD_INSERT_LIBRARIES"] ||
                environment[@"MallocStackLogging"] ||
                environment[@"NSZombieEnabled"] ||
                environment[@"__XDEBUGGER_PRESENT"] != nil) {
                isDebugging = YES;
            }
        }
    return isDebugging;
}


+ (intptr_t)getBaseAddr:(uint32_t)index{
    BOOL isDebugging = [Constant isDebuggerAttached];
    if(isDebugging){
        NSLog(@"The current app running with debugging");
        #if defined(__arm64__) || defined(__aarch64__)
        return 0;
        #endif
    }
    return _dyld_get_image_vmaddr_slide(index);
}


+ (NSArray<Class> *)getAllHackClasses {
    NSMutableArray<Class> *hackClasses = [NSMutableArray array];
    
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            Class class = classes[i];
            
            if (class_conformsToProtocol(class, @protocol(HackProtocol))) {
                [hackClasses addObject:class];
            }
        }
        free(classes);
    }
    return hackClasses;
}


+ (void)doHack:(NSString *)currentAppName {
    NSArray<Class> *personClasses = [Constant getAllHackClasses];
    
    for (Class class in personClasses) {
        id<HackProtocol> it = [[class alloc] init];
        NSString *appName = [it getAppName];
        if ([appName isEqualToString:currentAppName]) {
            // TODO 执行其他操作 ,比如 checkVersion
            [it hack];
            break;
        }
    }
}
@end