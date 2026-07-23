// Michael Oliva
// 7/9/26
// rgb app

import SwiftUI

struct ContentView: View {
    @StateObject var bluetooth = BluetoothManager()
    @State private var command = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(bluetooth.isConnected ?
                 "Connected" :
                 "Disconnected")
            TextField("Command",
                      text: $command)
            .textFieldStyle(.roundedBorder)
            
            Button("Send") {
                print("Command \(command)")
                bluetooth.send(command + "\n")
            }
            
            ScrollView {
                Text(bluetooth.recievedText)
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
