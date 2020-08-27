//
//  PacketTunnelProvider.swift
//  Tunnel
//
//  Created by yuany on 2020/8/24.
//  Copyright © 2020 yuany. All rights reserved.
//

import NetworkExtension
import os.log
import YYVPNLib

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var pendingCompletion: ((Error?) -> Void)?
    private var config: YYVPNManager.Config!
    private var udpSession: NWUDPSession!
    
    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log(.default, log: .default, "Starting tunnel, options: %{public}@", "\(String(describing: options))")
        do {
            guard let proto = protocolConfiguration as? NETunnelProviderProtocol else {
                throw NEVPNError(.configurationInvalid)
            }
            config = try YYVPNManager.Config(proto: proto)
        } catch {
            os_log(.default, log: .default, "Get configuration failed: %{public}@", error.localizedDescription)
            completionHandler(error)
        }
        
        os_log(.default, log: .default, "Get configuration: %{public}@", "\(String(describing: config))")
        
        pendingCompletion = completionHandler
        setupUDPSession()
        localPacketsToServer()
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}

private extension PacketTunnelProvider {
    func setupUDPSession() {
        let endPoint = NWHostEndpoint(hostname: config.hostname, port: config.port)
        udpSession = createUDPSession(to: endPoint, from: nil)
        setupTunnelNetworkSettings()
    }
    
    func setupTunnelNetworkSettings() {
        let ip = "192.168.0.2"
        let subnet = "255.255.255.0"
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.hostname)
        /// 分配给TUN接口的IPv4地址和网络掩码
        let ipv4Settings = NEIPv4Settings(addresses: [ip], subnetMasks: [subnet])
        /// 指定哪些IPv4网络流量的路由将被路由到TUN接口
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        setTunnelNetworkSettings(settings) { [weak self] error in
            self?.pendingCompletion?(error)
            if let error = error {
                os_log(.default, log: .default, "setTunnelNetworkSettings error: %{public}@", error.localizedDescription)
            } else {
                self?.remotePacketsToLocal()
            }
        }
    }
    
    func remotePacketsToLocal() {
        udpSession.setReadHandler({ [weak self] packets, _ in
            if let packets = packets {
                packets.forEach {
                    self?.packetFlow.writePackets([$0], withProtocols: [AF_INET as NSNumber])
                }
            }
        }, maxDatagrams: .max)
    }
    
    func localPacketsToServer() {
        os_log(.default, log: .default, "LocalPacketsToServer")
        packetFlow.readPackets { packets, _ in
            os_log(.default, log: .default, "readPackets")
            packets.forEach {
                self.udpSession.writeDatagram($0) { error in
                    if let error = error {
                        os_log(.default, log: .default, "udpSession.writeDatagram error: %{public}@", "\(error)")
                    }
                }
            }
            
            self.localPacketsToServer()
        }
    }
}
