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
    private var observer: AnyObject?
    private lazy var dataStorage = UserDefaults(suiteName: YYVPNManager.groupID)!
    
    /// 启动网络隧道，当主App调用startVPNTunnel()后执行；
    /// 最后通过调用completionHandler(nil or error)，完成建立隧道或由于错误而无法启动隧道。
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
    }
    
    /// 停止网络隧道，当主App调用stopVPNTunnel()或其他原因停止网络隧道时候执行；
    /// 如果想在PacketTunnelProvider内部停止，不能调用这个方法，应该调用cancelTunnelWithError()。
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        completionHandler()
    }
    
    /// 处理主App发送过来的消息，
    /// 主App可以通过`let session = manager.connection as? NETunnelProviderSession`，
    /// 再调用`session.sendProviderMessage(_ messageData: Data, responseHandler:)`向tunnel发送数据，
    /// tunnel回调completionHandler返回数据。
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    /// 当设备即将进入睡眠状态时，系统会调用此方法。
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    /// 当设备从睡眠模式唤醒时，系统会调用此方法。
    override func wake() {
        // Add code here to wake up.
    }
}

private extension PacketTunnelProvider {
    func setupUDPSession() {
        let endPoint = NWHostEndpoint(hostname: config.hostname, port: config.port)
        udpSession = createUDPSession(to: endPoint, from: nil)
        observer = udpSession.observe(\.state, options: [.new]) { [weak self] session, _ in
            self?.udpSession(session, didUpdateState: session.state)
        }
    }
    
    func udpSession(_ session: NWUDPSession, didUpdateState state: NWUDPSessionState) {
        switch state {
        case .ready:
            os_log(.default, log: .default, "Connet UDP Server successed!!")
            setupTunnelNetworkSettings()
            localPacketsToServer()
        case .failed:
            os_log(.default, log: .default, "Connet UDP Server failed")
            pendingCompletion?(NEVPNError(.connectionFailed))
            pendingCompletion = nil
        default:
            break
        }
    }
    
    /// 给虚拟网卡配置虚拟IP，DNS设置，代理设置，隧道MTU和IP路由
    func setupTunnelNetworkSettings() {
        let ip = "10.8.0.2"
        let subnet = "255.255.255.0"
        let dns = "8.8.8.8,8.4.4.4"
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.hostname)
        settings.mtu = 1400
        
        /// 分配给TUN接口的IPv4地址和网络掩码
        let ipv4Settings = NEIPv4Settings(addresses: [ip], subnetMasks: [subnet])
        /// 指定哪些IPv4网络流量的路由将被路由到TUN接口
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        let dnsSettings = NEDNSSettings(servers: dns.components(separatedBy: ","))
        /// overrides system DNS settings
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings
        
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
                    self?.dataStorage.receivePackets = ($0 as NSData).description
                    YYDarwinNotificationManager.sharedInstance().postNotification(forName: YYVPNManager.didReceivePacketsNotification)
                    self?.packetFlow.writePackets([$0], withProtocols: [AF_INET as NSNumber])
                }
            }
        }, maxDatagrams: .max)
    }
    
    func localPacketsToServer() {
        os_log(.default, log: .default, "LocalPacketsToServer")
        packetFlow.readPackets { [weak self] packets, _ in
            os_log(.default, log: .default, "readPackets")
            packets.forEach {
                self?.dataStorage.readPackets = ($0 as NSData).description
                YYDarwinNotificationManager.sharedInstance().postNotification(forName: YYVPNManager.didReadPacketsNotification)
                self?.udpSession.writeDatagram($0) { error in
                    if let error = error {
                        os_log(.default, log: .default, "udpSession.writeDatagram error: %{public}@", "\(error)")
                    }
                }
            }
            
            self?.localPacketsToServer()
        }
    }
}
