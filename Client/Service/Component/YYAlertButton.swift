//
//  YYAlertButton.swift
//  Client
//
//  Created by yuany on 2020/8/26.
//  Copyright © 2020 yuany. All rights reserved.
//

import SwiftUI

struct YYAlertButton: View {
    @State private var showAlert = false

    var text: String
    var title: String
    var message: String?
    var confirm: (() -> Void)?
    var cancel: (() -> Void)?

    var body: some View {
        Button(action: {
            self.showAlert = true
        }) {
            Text(text).foregroundColor(.red)
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text(title),
                message: Text(message ?? ""),
                primaryButton: .destructive(Text("确认"), action: { self.confirm?() }),
                secondaryButton: .cancel(Text("取消"), action: { self.cancel?() })
            )
        }
    }
}
