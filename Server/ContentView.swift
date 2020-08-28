//
//  ContentView.swift
//  Server
//
//  Created by yuany on 2020/8/24.
//  Copyright © 2020 yuany. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var items: [YYListView.Model] = []

    var body: some View {
        VStack {
            HStack {
                Text("接收数据中...")
                Button(action: clean) {
                    Text("clean")
                }
            }.fixedSize()
            YYListView(items: $items)
        }.onAppear(perform: starServer)
    }

    private func clean() {
        items.removeAll()
    }

    private func starServer() {
        YYServer.startUDPServer(8899) { str in
            self.items.append(.init(text: str))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
