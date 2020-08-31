//
//  YYListView.swift
//  Client
//
//  Created by yuany on 2020/8/31.
//  Copyright © 2020 yuany. All rights reserved.
//

import SwiftUI

extension YYListView {
    struct Model: Identifiable {
        var id = UUID()
        var text: String
    }
}

struct YYListView: View {
    @Binding var items: [Model]

    var body: some View {
        List(items) { item in
            Text(item.text)
        }
    }
}
