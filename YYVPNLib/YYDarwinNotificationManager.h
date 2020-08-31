//
//  YYDarwinNotificationManager.h
//  vpn-service
//
//  Created by yuany on 2020/8/22.
//  Copyright © 2020 huan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^YYDarwinNotificationManagerHandler)(void);

/// 如果是Darwin notification center, 无法传递参数
@interface YYDarwinNotificationManager : NSObject

+ (_Nonnull instancetype)sharedInstance;

- (void)registerNotificationForName:(NSString *_Nonnull)name callback:(YYDarwinNotificationManagerHandler _Nullable)callback;
- (void)postNotificationForName:(NSString *_Nonnull)name;

@end

