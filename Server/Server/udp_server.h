//
//  udp_server.h
//  vpn-client
//
//  Created by yuany on 2020/8/17.
//  Copyright © 2020 huan. All rights reserved.
//

#ifndef udp_server_h
#define udp_server_h

#include <stdio.h>

typedef void (*data_handler_t)(char *, long);

#define ANET_OK      0
#define ANET_ERR    -1

void udp_server_start(int port);
void set_data_handler(data_handler_t handler);

#endif /* udp_server_h */
