//
//  YYServer.m
//  Server
//
//  Created by yuany on 2020/8/21.
//  Copyright © 2020 huan. All rights reserved.
//

#import "YYServer.h"
#include "udp_server.h"
#include "udp_client.h"

int port = 8899;

DataHandler dataHandler;

@implementation YYServer

+ (void)startUDPServerHandler:(DataHandler)handler {
    [self startUDPServer:port dataHandler:handler];
}
+ (void)startUDPClient {
    [self startUDPClientToServer:@"127.0.0.1" port:port];
}

void data_handler(char *udpbuf, long len) {
    if (dataHandler) {
        NSData *udpData = [NSData dataWithBytes:udpbuf length:len];
        NSString *data = udpData.description;
        NSLog(@"data_handler ------- %@", data);
        dispatch_async(dispatch_get_main_queue(), ^{
            dataHandler(data);
        });
    }
}

+ (void)startUDPServer:(NSInteger)port dataHandler:(DataHandler)handler {
    dataHandler = handler;
    set_data_handler(data_handler);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        udp_server_start((int)port);
    });
}

+ (void)startUDPClientToServer:(NSString *)server port:(NSInteger)port {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        udp_client_start(server.UTF8String, (int)port);
    });
}

@end

