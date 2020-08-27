//
//  ConfigViewModel.swift
//  Client
//
//  Created by yuany on 2020/8/24.
//  Copyright © 2020 yuany. All rights reserved.
//

import Foundation
import Combine
import YYVPNLib

final class ConfigViewModel: ObservableObject {
    @Published var config: YYVPNManager.Config
    @Published var status = YYVPNManager.Status.off
    
    init(config: YYVPNManager.Config) {
        self.config = config
        YYVPNManager.shared.statusDidChangeHandler = { [weak self] status in
            self?.status = status
        }
    }
    
    func didTapStart() {
        YYVPNManager.shared.start(with: config) { error in
            
        }
    }
    
    func didTapStop() {
        YYVPNManager.shared.stop()
    }
    
    func didTapRemove() {
        YYVPNManager.shared.removeFromPreferences { error in
            
        }
    }
}
