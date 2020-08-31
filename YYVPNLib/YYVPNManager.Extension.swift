//
//  YYVPNManager.Extension.swift
//  YYVPNLib
//
//  Created by yuany on 2020/8/25.
//  Copyright © 2020 yuany. All rights reserved.
//

import Foundation
import NetworkExtension

public extension NETunnelProviderManager {
    func config(with config: YYVPNManager.Config) {
        guard let proto = protocolConfiguration as? NETunnelProviderProtocol else {
            return
        }
        
        proto.serverAddress = "\(config.hostname):\(config.port)"
        protocolConfiguration = proto
    }
}

public extension UserDefaults {
    var readPackets: String? {
        get {
            string(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var receivePackets: String? {
        get {
            string(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
}
