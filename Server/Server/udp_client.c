//
//  udp_client.c
//  vpn-client
//
//  Created by yuany on 2020/8/17.
//  Copyright © 2020 huan. All rights reserved.
//

#include "udp_client.h"
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

#define BUFF_LEN 1024

void udp_msg_sender(int fd, struct sockaddr *dst) {
    char buf[BUFF_LEN];
    int count = 0;
    struct sockaddr_in src;
    socklen_t len = sizeof(*dst);
    while (1) {
        bzero(buf, sizeof(buf));
        sprintf(buf, "Test udp msg %d!\n", count++);
        ///打印自己发送的信息
        printf("client:%s\n",buf);
        sendto(fd, buf, BUFF_LEN, 0, dst, len);
        
        ///接收来自server的信息
        bzero(buf, sizeof(buf));
        recvfrom(fd, buf, BUFF_LEN, 0, (struct sockaddr *)&src, &len);
        printf("server:%s\n",buf);
        sleep(1);
    }
}

void udp_client_start(const char *ip, int port) {
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) {
        printf("creating socket failed:[%s]", strerror(errno));
        return;
    }
    
    struct sockaddr_in sa;
    bzero(&sa, sizeof(sa));
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = inet_addr(ip);
    sa.sin_port = htons(port);
    
    udp_msg_sender(fd, (struct sockaddr *)&sa);
    
    close(fd);
}

























