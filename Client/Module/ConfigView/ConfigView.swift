//
//  ConfigView.swift
//  Client
//
//  Created by yuany on 2020/8/24.
//  Copyright © 2020 yuany. All rights reserved.
//

import SwiftUI

struct ConfigView: View {
    
    @ObservedObject var viewModel =
        ConfigViewModel(config: .init(hostname: "121.4.91.20", port: "54345"))

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Settings")) {
                    HStack(alignment: .center) {
                        Text("IP").font(.callout)
                        TextField("IP", text: $viewModel.config.hostname)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    HStack(alignment: .center) {
                        Text("Port").font(.callout)
                        TextField("Port", text: $viewModel.config.port)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Status")) {
                    Text("Status: ") + Text(viewModel.status.rawValue)
                    if viewModel.status == .off || viewModel.status == .invalid {
                        Button(action: {
                            self.hideKeyboard()
                            self.viewModel.didTapStart()
                        }) {
                            Text("Start")
                        }
                    } else {
                        Button(action: {
                            self.hideKeyboard()
                            self.viewModel.didTapStop()
                        }) {
                            Text("Stop")
                        }
                    }
                }
                
                if viewModel.status == .on {
                    Section {
                        NavigationLink(destination: PacketView()) {
                            Text("Show packets View")
                        }
                    }
                }

                Section {
                    YYAlertButton(text: "Remove",
                                  title: "确定删除?",
                                  message: nil,
                                  confirm: {
                                      self.viewModel.didTapRemove()
                                  },
                                  cancel: nil)
                }
            }
            .navigationBarTitle("VPN Status")
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView()
    }
}
