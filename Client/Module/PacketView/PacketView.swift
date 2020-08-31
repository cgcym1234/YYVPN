//
//  PacketView.swift
//  Client
//
//  Created by yuany on 2020/8/31.
//  Copyright © 2020 yuany. All rights reserved.
//

import SwiftUI
import YYVPNLib

struct PacketView: View {
    @State var sendPackets: [YYListView.Model] = []
    @State var receviedPackets: [YYListView.Model] = []
    private let dataStorage = UserDefaults(suiteName: YYVPNManager.groupID)!

    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("发送的包")
                    Button(action: cleanSendPackets) {
                        Text("clean")
                    }
                }.fixedSize()
                YYListView(items: $sendPackets)
            }
            Group {
                HStack {
                    Text("接收的包")
                    Button(action: cleanReceviedPackets) {
                        Text("clean")
                    }
                }.fixedSize()
                YYListView(items: $receviedPackets)
            }
        }.onAppear(perform: starListening)
    }

    private func cleanSendPackets() {
        sendPackets.removeAll()
    }

    private func cleanReceviedPackets() {
        receviedPackets.removeAll()
    }

    private func starListening() {
        YYDarwinNotificationManager.sharedInstance().registerNotification(forName: YYVPNManager.didReadPacketsNotification) {
            if let data = self.dataStorage.readPackets {
                DispatchQueue.main.async {
                    self.sendPackets.append(.init(text: data))
                }
            }
        }

        YYDarwinNotificationManager.sharedInstance().registerNotification(forName: YYVPNManager.didReceivePacketsNotification) {
            if let data = self.dataStorage.receivePackets {
                DispatchQueue.main.async {
                    self.receviedPackets.append(.init(text: data))
                }
            }
        }
    }
}
