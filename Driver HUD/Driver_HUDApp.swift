//
//  Driver_HUDApp.swift
//  Driver HUD
//
//  Created by Dev Aditya on 12/17/25.
//

import SwiftUI

@main
struct Driver_HUDApp: App {

    @State private var appModel = AppModel()
    @State private var avPlayerViewModel = AVPlayerViewModel()

 
    @StateObject private var telemetry = TelemetryClient()

    var body: some Scene {
        WindowGroup {
            Group {
                if avPlayerViewModel.isPlaying {
                    AVPlayerView(viewModel: avPlayerViewModel)
                } else {
                    ContentView()
                }
            }
            // ✅ Inject AppModel + Telemetry for BOTH branches
            .environment(appModel)
            .environmentObject(telemetry)
            // ✅ Start UDP listener once
            .task {
                telemetry.startListening(port: 4444)
            }
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                // ✅ Inject telemetry into ImmersiveView (required)
                .environmentObject(telemetry)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    avPlayerViewModel.play()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    avPlayerViewModel.reset()
                }
        }
        .immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}
