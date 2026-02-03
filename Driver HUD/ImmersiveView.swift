//
//  ImmersiveView.swift
//  BeamNG HUD
//
//  Created by Dev Aditya on 12/17/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @EnvironmentObject var telemetry: TelemetryClient

    var body: some View {
        RealityView { content, attachments in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }

            // Add a SwiftUI-driven HUD as an attachment entity in front of the user
            if let hud = attachments.entity(for: "hud") {
                hud.position = [0, 1.35, -1.0]     // ~1m in front, slightly above center
                hud.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                content.add(hud)
            }
        } attachments: {
            Attachment(id: "hud") {
                VStack(spacing: 10) {
                    Text("BeamNG HUD")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("\(telemetry.speedMph, specifier: "%.1f") mph")
                        .font(.system(size: 54, weight: .bold, design: .rounded))

                    Text("RPM \(Int(telemetry.rpm))")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Packets: \(telemetry.packets)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(22)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }
}

#Preview(immersionStyle: .progressive) {
    ImmersiveView()
        .environment(AppModel())
        .environmentObject(TelemetryClient())
}
