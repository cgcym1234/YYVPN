//
//  YYVPNManager.swift
//  YYVPNLib
//
//  Created by yuany on 2020/8/24.
//  Copyright © 2020 yuany. All rights reserved.
//

import Foundation
import NetworkExtension

extension YYVPNManager {
    public static var bundleID = "com.yy.Client112"
    public static var bundleIDTunnel = "\(bundleID).Tunnel"
    public static var groupID = "group.\(bundleID)"
}

public final class YYVPNManager {
    public typealias Handler = (Error?) -> Void

    public static let shared = YYVPNManager()

    public var statusDidChangeHandler: ((Status) -> Void)?
    public private(set) var tunnel: NETunnelProviderManager?
    public var isOn: Bool { status == .on }
    public private(set) var status: Status = .off {
        didSet { notifyStatusDidChange() }
    }

    private var observers = [AnyObject]()

    private init() {
        refresh()
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .NEVPNStatusDidChange,
                object: nil,
                queue: OperationQueue.main
            ) { [weak self] _ in
                self?.updateStatus()
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(
                forName: .NEVPNConfigurationChange,
                object: nil,
                queue: OperationQueue.main
            ) { [weak self] _ in
                self?.refresh()
            }
        )
    }
}

public extension YYVPNManager {
    func start(with config: Config,
               completion: @escaping Handler) {
        loadTunnelManager { [unowned self] manager, error in
            if let error = error {
                return completion(error)
            }

            if manager == nil {
                self.tunnel = self.makeTunnelManager(with: config)
            }

            self.saveToPreferences(with: config) { [weak self] error in
                if let error = error {
                    return completion(error)
                }

                self?.tunnel?.loadFromPreferences() { [weak self] _ in
                    self?.start(completion)
                }
            }
        }
    }

    func start(_ completion: @escaping Handler) {
        do {
            try tunnel?.connection.startVPNTunnel()
        } catch {
            completion(error)
        }
    }

    func stop() {
        tunnel?.connection.stopVPNTunnel()
    }

    func refresh(completion: Handler? = nil) {
        loadTunnelManager { [weak self] _, error in
            self?.updateStatus()
            completion?(error)
        }
    }

    func setEnabled(_ isEnabled: Bool, completion: @escaping Handler) {
        guard isEnabled != tunnel?.isEnabled else { return }
        tunnel?.isEnabled = isEnabled
        saveToPreferences(completion: completion)
    }

    func saveToPreferences(with config: Config? = nil,
                           completion: @escaping Handler) {
        if let config = config {
            tunnel?.config(with: config)
        }
        tunnel?.saveToPreferences { error in
            completion(error)
        }
    }

    func removeFromPreferences(completion: @escaping Handler) {
        tunnel?.removeFromPreferences { [weak self] error in
            if error != nil {
                self?.tunnel = nil
            }
            completion(error)
        }
    }
}

private extension YYVPNManager {
    func loadTunnelManager(_ complition: @escaping (NETunnelProviderManager?, Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [unowned self] managers, error in
            self.tunnel = managers?.first
            complition(managers?.first, error)
        }
    }

    func makeTunnelManager(with config: Config) -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = YYVPNManager.bundleIDTunnel
        proto.serverAddress = "YYVPN"
        /// passwordReference必须取keychain里面的值
//        proto.passwordReference = Data()
        manager.protocolConfiguration = proto
        manager.localizedDescription = "YYVPN"
        manager.isEnabled = true

        return manager
    }

    func updateStatus() {
        if let tunnel = tunnel {
            status = Status(tunnel.connection.status)
        } else {
            status = .off
        }

        print(status)
    }

    func notifyStatusDidChange() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: YYVPNManager.didChangeStatusNotification),
            object: nil
        )
        statusDidChangeHandler?(status)
    }
}
