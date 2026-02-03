import Foundation
import Network
import Combine

struct OutGaugePacket {
    let speedMph: Double
    let rpm: Double

    init?(data: Data) {
        guard data.count >= 20 else { return nil }

        func readFloat32LE(_ offset: Int) -> Float {
            let raw: UInt32 = data.withUnsafeBytes { buf in
                buf.load(fromByteOffset: offset, as: UInt32.self)
            }
            return Float(bitPattern: UInt32(littleEndian: raw))
        }

        let speedMs = readFloat32LE(12)
        let rpmRaw  = readFloat32LE(16)

        self.speedMph = Double(speedMs * 2.23694)
        self.rpm = Double(rpmRaw)
    }
}

final class TelemetryClient: ObservableObject {
    @Published var speedMph: Double = 0
    @Published var rpm: Double = 0
    @Published var packets: Int = 0

    private var listener: NWListener?

    func startListening(port: UInt16 = 4444) {
        guard listener == nil else { return }

        do {
            let nwPort = NWEndpoint.Port(rawValue: port)!
            let listener = try NWListener(using: .udp, on: nwPort)
            self.listener = listener

            listener.stateUpdateHandler = { state in
                print("UDP listener state: \(state)")
            }

            listener.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .global(qos: .userInitiated))
                self?.receive(on: connection)
            }

            listener.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Failed to start UDP listener: \(error)")
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            if let data = data,
               let packet = OutGaugePacket(data: data) {
                DispatchQueue.main.async {
                    self?.speedMph = packet.speedMph
                    self?.rpm = packet.rpm
                    self?.packets = (self?.packets ?? 0) + 1
                }
            }

            if error == nil {
                self?.receive(on: connection)
            } else {
                print("UDP receive error: \(String(describing: error))")
            }
        }
    }
}
