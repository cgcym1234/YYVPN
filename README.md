# YYVPN

## 环境

- Xcode 11.6
- iOS 13
- MacOS 10.15

## 导航

> [1-总览](https://www.jianshu.com/p/2a64c36dd63b)
>
> [2-Client开发](https://www.jianshu.com/p/989687822a2b)
>
> [3-Tunnel开发](https://www.jianshu.com/p/b90513c1bc52)
>
> [4-Server开发](https://www.jianshu.com/p/ce87c647aa4f)
>
> [5-App和Extension通信](https://www.jianshu.com/p/1427937cbcc1)

[完整代码在此](https://github.com/cgcym1234/YYVPN)，熟悉的小伙伴可以直接试试。

## 前言

之前用NEKit框架写过一个自用的[科学上网工具](https://github.com/cgcym1234/vpn_ss)，后面还写过一个代理http/https的App，虽然都做出来了，但它们核心功能都是NEKit封装好了的，所以对Network Extension的理解还是微乎其微。

最近想再学习下网络这块，所以又看了些资料，也稍微深入的学习下Network Extension。

## 目标

一个iOS客户端App，一个MacOS服务器App，功能如下：

1. 开启自己的App后，抓取手机所有的流量，发送到自己的代理服务器
2. 代理服务器转发所有请求到真正的服务器
3. 代理服务器收到响应后，再回传给App

最后实现效果如下：

Client:

![](http://120.79.102.161/Blogs/note/Blog/MyPic/vpn/client.png)



Server:

![](http://120.79.102.161/Blogs/note/Blog/MyPic/vpn/server.jpg)

先来看看，要实现上面流程需要用到哪些技术。

## 涉及技术

- Network Extension
- Swift UI，Combine
- 多Target共享代码，相互通信
- C语言Socket编程

客户端App使用Swift UI构建界面，使用Network Extension的NEPacketTunnelProvider抓取手机的IP数据包，通过UDP发送给服务器。

服务器App也使用Swift UI构建界面，使用C语言的Socket编程处理收到的数据。

流程如下图：

```
+-----+            +---------+              +-------+           +---------+
| App |            | Tunnel  |              | Proxy |           | Server  |
+-----+            +---------+              +-------+           +---------+
   |                    |                       |                    |
   | Real request       |                       |                    |
   |------------------->|                       |                    |
   |                    | ------------------\   |                    |
   |                    |-| ReadPackets(IP) |   |                    |
   |                    | |-----------------|   |                    |
   |                    |                       |                    |
   |                    | Packaging to UDP      |                    |
   |                    |---------------------->|                    |
   |                    |                       |                    |
   |                    |                       | Real request       |
   |                    |                       |------------------->|
   |                    |                       |                    |
   |                    |                       |      Real Response |
   |                    |                       |<-------------------|
   |                    |                       |                    |
   |                    |      Packaging to UDP |                    |
   |                    |<----------------------|                    |
   |   ---------------\ |                       |                    |
   |   | WritePackets |-|                       |                    |
   |   |--------------| |                       |                    |
   |                    |                       |                    |
   |      Real response |                       |                    |
   |<-------------------|                       |                    |
   |                    |                       |                    |
```

后面就来一步步讲解。

## 参考链接

- [Let's Build a VPN Protocol系列](https://kean.blog/post/lets-build-vpn-protocol)

- [网络虚拟化技术（二）: TUN/TAP MACVLAN MACVTAP](https://blog.kghost.info/2013/03/27/linux-network-tun/)