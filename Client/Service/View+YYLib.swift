//
//  View+YYLib.swift
//  Client
//
//  Created by yuany on 2020/8/27.
//  Copyright © 2020 yuany. All rights reserved.
//

import SwiftUI

public extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

