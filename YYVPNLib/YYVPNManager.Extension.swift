//
//  YYVPNManager.Extension.swift
//  YYVPNLib
//
//  Created by yuany on 2020/8/25.
//  Copyright © 2020 yuany. All rights reserved.
//

import Foundation
import NetworkExtension

extension NETunnelProviderManager {
    public func config(with config: YYVPNManager.Config) {
        guard let proto = protocolConfiguration as? NETunnelProviderProtocol else {
            return
        }
        
        proto.serverAddress = "\(config.hostname):\(config.port)"
        protocolConfiguration = proto
    }
}
