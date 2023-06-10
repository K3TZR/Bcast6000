//
//  ContentView.swift
//  Bcast6000
//
//  Created by Douglas Adams on 6/8/23.
//

import SwiftUI

import FlexApi

        
        
struct ContentView: View {
  
  var choices = [1, 2, 3, 4, 5]
  @State private var selection = 1
  @State private var isBroadcasting = false

  @StateObject var broadcaster = Broadcaster(port: 4992)
  
  var body: some View {
    VStack {
      Picker("Number of Radios", selection: $selection) {
        ForEach(choices, id: \.self) {
          Text("\($0)").tag($0)
        }
      }

      .frame(width: 160, alignment: .leading)
      Button(isBroadcasting ? "Stop" : "Start") {
        isBroadcasting.toggle()
        if isBroadcasting {
          broadcaster.start(numberOfRadios: selection, interval: 1)
        } else {
          broadcaster.stop()
        }
      }
    }
    .padding()
  }
}
        
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
