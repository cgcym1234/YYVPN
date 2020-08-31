//
//  YYDarwinNotificationManager.m
//  vpn-service
//
//  Created by yuany on 2020/8/22.
//  Copyright © 2020 huan. All rights reserved.
//

#import "YYDarwinNotificationManager.h"

@implementation YYDarwinNotificationManager {
    NSMutableDictionary<NSString *, YYDarwinNotificationManagerHandler> *handlers;
}

+ (instancetype)sharedInstance {
    static id instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        handlers = [NSMutableDictionary new];
    }
    return self;
}

- (void)registerNotificationForName:(NSString *)name callback:(YYDarwinNotificationManagerHandler)callback {
    handlers[name] = callback;
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, (__bridge const void *)(self), defaultNotificationCallback, (__bridge CFStringRef)name, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)postNotificationForName:(NSString *)name {
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(center, (__bridge CFStringRef)name, NULL, NULL, YES);
}

static void defaultNotificationCallback(CFNotificationCenterRef center,
                                        void *observer,
                                        CFStringRef name,
                                        const void *object,
                                        CFDictionaryRef userInfo) {
//    NSLog(@"YYDarwinNotificationManager Callback name: %@", name);
    NSString *identifier = (__bridge NSString *)name;
    
    YYDarwinNotificationManagerHandler handler = [YYDarwinNotificationManager sharedInstance]->handlers[identifier];
    if (handler) {
        handler();
    }
}

- (void)dealloc {
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveEveryObserver(center, (__bridge const void *)(self));
}


@end
