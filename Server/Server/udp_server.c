//
//  udp_server.c
//  vpn-client
//
//  Created by yuany on 2020/8/17.
//  Copyright © 2020 huan. All rights reserved.
//

#include "udp_server.h"
#include <stdio.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <string.h>
#include <netdb.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <arpa/inet.h>
#include <pthread/pthread.h>
#include <net/if.h>

#define BUFF_LEN 1500

data_handler_t datahandler;

void set_data_handler(data_handler_t handler) {
    datahandler = handler;
}

void handle_udp_datagram(int fd) {
    char buf[BUFF_LEN];
    long count;
    struct sockaddr_in client;
    socklen_t len;
    while (1) {
        bzero(buf, sizeof(buf));
        len = sizeof(client);
        /// 写一个长度为0的数据报是可行的。
        /// 在UDP情况下，这会形成一个只包含一个IP首部（对于IPv4通常为20个字节，对于IPv6通常为40个字节）
        /// 和一个8字节UDP首部而没有数据的IP数据报。
        /// 这也意味着对于数据报协议，recvfrom返回0值是可接受的：
        /// 它并不像TCP套接字上read返回0值那样表示对端已关闭连接。
        /// 既然UDP是无连接的，因此也就没有诸如关闭一个UDP连接之类事情。
        /// 如果recvfrom的from参数是一个空指针，那么相应的长度参数（addrlen）也必须是一个空指针，
        /// 表示我们并不关心数据发送者的协议地址。
        /// recvfrom和sendto都可以用于TCP，尽管通常没有理由这样做。
        count = recvfrom(fd, buf, BUFF_LEN, 0, (struct sockaddr *)&client, &len);
        if (count == ANET_ERR) {
            printf("recieve data failed:[%s]\n", strerror(errno));
            return;
        }
        
        ///打印client发过来的信息
//        printf("client:%s\n",buf);
        
        if (datahandler != NULL) {
            datahandler(buf, count);
        }
        
        sendto(fd, buf, count, 0, (struct sockaddr*)&client, len);
    }
}

static int upd_server(int port) {
    ///AF_INET:IPV4;SOCK_DGRAM:UDP
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) {
        printf("creating socket failed:[%s]\n", strerror(errno));
        return ANET_ERR;
    }
    
    struct sockaddr_in sa;
    bzero(&sa, sizeof(sa));
    sa.sin_family = AF_INET;
    ///IP地址，需要进行网络序转换，INADDR_ANY：本地地址
    sa.sin_addr.s_addr = htonl(INADDR_ANY);
    sa.sin_port = htons(port);
    
    int ret = bind(fd, (struct sockaddr *)&sa, sizeof(sa));
    if (ret < 0) {
        printf("bind failed:[%s]\n", strerror(errno));
        close(fd);
        return ANET_ERR;
    }
    
    return fd;
}

void udp_server_start(int port) {
    int fd = upd_server(port);
    if (fd > 0) {
        handle_udp_datagram(fd);
        close(fd);
    }
}






















