//
//  YYServer.h
//  Server
//
//  Created by yuany on 2020/8/21.
//  Copyright © 2020 huan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DataHandler)(NSString *data);

@interface YYServer : NSObject

+ (void)startUDPServerHandler:(DataHandler)handler;
+ (void)startUDPClient;

+ (void)startUDPServer:(NSInteger)port dataHandler:(DataHandler)handler;
+ (void)startUDPClientToServer:(NSString *)server port:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END
