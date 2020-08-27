//
//  YYVPNManager.Config.swift
//  YYVPNLib
//
//  Created by yuany on 2020/8/24.
//  Copyright © 2020 yuany. All rights reserved.
//

import Foundation
import NetworkExtension
import os.log

public extension YYVPNManager {
    static let didChangeStatusNotification = "YYVPNManager.didChangeStatusNotification"
    
    enum Status: String {
        case on
        case off
        case invalid /// The VPN is not configured
        case connecting
        case disconnecting
        
        public init(_ status: NEVPNStatus) {
            switch status {
            case .connected:
                self = .on
            case .connecting, .reasserting:
                self = .connecting
            case .disconnecting:
                self = .disconnecting
            case .disconnected, .invalid:
                self = .off
            @unknown default:
                self = .off
            }
        }
    }
}

extension YYVPNManager {
    public struct Config {
        public let groupID = "group.com.yy.Client"
        public let bundleID = "com.yy.Client"
        public let bundleIDTunnel = "com.yy.Client.Tunnel"
        
        public var username: String = ""
        public var password: String = ""
        public var hostname: String
        public var port: String

        public init(hostname: String,
                    port: String) {
            self.hostname = hostname
            self.port = port
        }

        public init(proto: NETunnelProviderProtocol) throws {
            guard let fullServerAddress = proto.serverAddress else {
                throw NEVPNError(.configurationInvalid)
            }
            os_log(.default, log: .default, "fullServerAddress: %{public}s", fullServerAddress)
            let serverAddressParts = fullServerAddress.split(separator: ":")
            guard serverAddressParts.count == 2 else {
                throw NEVPNError(.configurationInvalid)
            }

            self.hostname = String(serverAddressParts[0])
            self.port = String(serverAddressParts[1])
            os_log(.default, log: .default, "serverAddressParts: %{public}@", serverAddressParts)
        }
    }
}
