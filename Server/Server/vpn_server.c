//
//  vpn_server.c
//  Server
//
//  Created by yangyuan on 2020/12/9.
//  Copyright © 2020 yuany. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <netdb.h>
#include <fcntl.h>
#include <signal.h>
#include <linux/if.h>
#include <linux/if_tun.h>

#define PORT 54354
#define MTU 1400
#define BIND_HOST "0.0.0.0"
#define PATH_TUN "/dev/net/tun"

void cleanup_route_table(void);

static int max(int a, int b) {
    return a > b ? a: b;
}

static void log_error(const char *fmt, ...) {
    fprintf(stderr, "%s", fmt);
}

static void run(char *cmd) {
    printf("Execute `%s`\n", cmd);
    if (system(cmd)) {
        log_error(cmd);
        exit(1);
    }
}

void yy_encrypt(char *plantext, char *ciphertext, size_t len) {
    memcpy(ciphertext, plantext, len);
}

void yy_decrypt(char *ciphertext, char *plantext, size_t len) {
    memcpy(plantext, ciphertext, len);
}

/// Catch Ctrl-C and `kill`s, make sure route table gets cleaned before this process exit
void cleanup(int signo) {
    printf("Goodbye, cruel world...\n");
    if (signo == SIGHUP || signo == SIGINT || signo == SIGTERM) {
        cleanup_route_table();
        exit(0);
    }
}

void cleanup_when_sig_exit() {
    struct sigaction sa;
    sa.sa_handler = &cleanup;
    sa.sa_flags = SA_RESTART;
    sigfillset(&sa.sa_mask);
    
    if (sigaction(SIGHUP, &sa, NULL)) {
        log_error("Cannot handle SIGHUP");
    }
    if (sigaction(SIGINT, &sa, NULL)) {
        log_error("Cannot handle SIGINT");
    }
    if (sigaction(SIGTERM, &sa, NULL)) {
        log_error("Cannot handle SIGTERM");
    }
}

/// Create VPN interface /dev/tun0 and return a fd
int tun_alloc() {
    struct ifreq ifr;
    int fd, e;
    
    if ((fd = open(PATH_TUN, O_RDWR)) < 0) {
        log_error("Cannot open %s", PATH_TUN);
        return -1;
    }
    
    bzero(&ifr, sizeof(ifr));
    ifr.ifr_flags = IFF_TUN | IFF_NO_PI;
    strncpy(ifr.ifr_name, "tun0", IFNAMSIZ);
    
    if ((e = ioctl(fd, TUNSETIFF, (void *)&ifr)) < 0) {
        log_error("ioctl[TUNSETIFF]");
        close(fd);
        return -1;
    }
    
    return fd;
}

/// Configure IP address and MTU of VPN interface /dev/tun0
void ifconfig() {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "ifconfig tun0 10.8.0.1/16 mtu %d up", MTU);
    run(cmd);
}

/// Setup route table via `iptables` & `ip route`
void setup_route_table() {
    run("sysctl -w net.ipv4.ip_forward=1");
    run("iptables -t nat -A POSTROUTING -s 10.8.0.0/16 ! -d 10.8.0.0/16 -m comment --comment 'vpndemo' -j MASQUERADE");
    run("iptables -A FORWARD -s 10.8.0.0/16 -m state --state RELATED,ESTABLISHED -j ACCEPT");
    run("iptables -A FORWARD -d 10.8.0.0/16 -j ACCEPT");
}

void cleanup_route_table() {
    run("iptables -t nat -D POSTROUTING -s 10.8.0.0/16 ! -d 10.8.0.0/16 -m comment --comment 'vpndemo' -j MASQUERADE");
    run("iptables -D FORWARD -s 10.8.0.0/16 -m state --state RELATED,ESTABLISHED -j ACCEPT");
    run("iptables -D FORWARD -d 10.8.0.0/16 -j ACCEPT");
}

int udp_bind(struct sockaddr *addr, socklen_t *addrlen) {
    struct addrinfo hints;
    struct addrinfo *result;
    int sock, flags;
    
    bzero(&hints, sizeof(hints));
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_protocol = IPPROTO_UDP;
    
    const char *host = BIND_HOST;
    if (getaddrinfo(host, NULL, &hints, &result) != 0) {
        log_error("getaddrinfo error");
        return -1;
    }
    
    if (result->ai_family == AF_INET) {
        ((struct sockaddr_in*)result->ai_addr)->sin_port = htons(PORT);
    } else if (result->ai_family == AF_INET6) {
        ((struct sockaddr_in6*)result->ai_addr)->sin6_port = htons(PORT);
    } else {
        log_error("unknown ai_family %d", result->ai_family);
        freeaddrinfo(result);
        return -1;
    }
    
    memcpy(addr, result->ai_addr, result->ai_addrlen);
    *addrlen = result->ai_addrlen;
    
    if ((sock = socket(result->ai_family, SOCK_DGRAM, IPPROTO_UDP)) == -1) {
        log_error("cannot create socket");
        freeaddrinfo(result);
        return -1;
    }
    
    if (bind(sock, result->ai_addr, result->ai_addrlen) != 0) {
        log_error("bind error");
        close(sock);
        freeaddrinfo(result);
        return -1;
    }
    
    freeaddrinfo(result);
    flags = fcntl(sock, F_GETFL, 0);
    if (flags != -1 && fcntl(sock, F_SETFL, flags | O_NONBLOCK) != -1) {
        return sock;
    }
    
    log_error("fcntl error");
    close(sock);
    return -1;
}




int main(int argc, char **argv) {
    int tunfd;
    if ((tunfd = tun_alloc()) < 0) {
        return -1;
    }
    
    ifconfig();
    setup_route_table();
    cleanup_when_sig_exit();
    
    int udpfd;
    struct sockaddr_storage client_addr;
    socklen_t client_addrlen = sizeof(client_addr);
    
    if ((udpfd = udp_bind((struct sockaddr *)&client_addr, &client_addrlen)) < 0) {
        return -1;
    }
    
    /*
     * tun_buf - memory buffer read from/write to tun dev - is always plain
     * udp_buf - memory buffer read from/write to udp fd - is always encrypted
     */
    char tun_buf[MTU], udp_buf[MTU];
    bzero(tun_buf, MTU);
    bzero(udp_buf, MTU);
    
    while (1) {
        fd_set readset;
        FD_ZERO(&readset);
        FD_SET(tun_fd, &readset);
        FD_SET(udp_fd, &readset);
        int max_fd = max(tun_fd, udp_fd) + 1;
        printf("-----------selecting----------\n");
        if (select(maxfd, &readset, NULL, NULL, NULL) == -1) {
            log_error("select error");
            break;
        }
        
        size_t r;
        if (FD_ISSET(tunfd, &readset)) {
            r = read(tunfd, tun_buf, MTU);
            printf("recvfrom tun %zu bytes ...\n", r);
            if (r < 0) {
                log_error("read from tun_fd error");
                break;
            }
            
            yy_encrypt(tun_buf, udp_buf, r);
            printf("Writing to UDP %zu bytes ...\n", r);
            
            r = sendto(udpfd, udp_buf, r, 0, (const struct sockaddr *)&client_addr, client_addrlen);
            if (r < 0) {
                log_error("sendto udp_fd error");
                break;
            }
        }
        
        if (FD_ISSET(udpfd, &readset)) {
            r = recvfrom(udpfd, udp_buf, MTU, 0, (struct sockaddr *)&client_addr, &client_addrlen);
            printf("recvfrom UDP %zu bytes ...\n", r);
            if (r < 0) {
                log_error("recvfrom udp_fd error");
                break;
            }
            
            yy_decrypt(udp_buf, tun_buf, r);
            
            printf("Writing to tun %zu bytes ...\n", r);
            r = write(tunfd, tun_buf, r);
            if (r < 0) {
                log_error("write tun_fd error");
                break;
            }
        }
    }
    
    close(tunfd);
    close(udpfd);
    
    cleanup_route_table();
    
    return 0;
}













