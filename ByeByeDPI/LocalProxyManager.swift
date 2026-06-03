import Foundation
import Network

final class LocalProxyManager: ObservableObject {
    static let shared = LocalProxyManager()

    @Published var isRunning = false

    private var listener: NWListener?

    private init() {}

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func start() {
        do {
            let params = NWParameters.tcp
            let listener = try NWListener(using: params, on: 1080)
            listener.service = .init(type: "_http._tcp", name: "ByeByeDPI Proxy")

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener.stateUpdateHandler = { [weak self] state in
                if case .ready = state {
                    DispatchQueue.main.async { self?.isRunning = true }
                }
            }

            listener.start(queue: .global(qos: .utility))
            self.listener = listener
        } catch {
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let data = data, error == nil else {
                connection.cancel()
                return
            }

            if let request = String(data: data, encoding: .utf8),
               request.hasPrefix("CONNECT ") {
                self?.handleConnectTunnel(request, data, connection)
            } else {
                self?.handleHttpProxy(requestData: data, connection: connection)
            }
        }
    }

    private func handleConnectTunnel(_ request: String, _ data: Data, _ connection: NWConnection) {
        guard let targetInfo = extractTarget(from: request) else {
            connection.send(content: "HTTP/1.1 400 Bad Request\r\n\r\n".data(using: .utf8), completion: .contentProcessed({ _ in connection.cancel() }))
            return
        }

        let target = NWConnection(host: NWEndpoint.Host(targetInfo.host), port: NWEndpoint.Port(rawValue: targetInfo.port) ?? 443, using: .tcp)
        target.start(queue: .global(qos: .utility))

        target.stateUpdateHandler = { [weak connection] state in
            guard case .ready = state, let connection = connection else { return }
            connection.send(content: "HTTP/1.1 200 Connection Established\r\n\r\n".data(using: .utf8), completion: .contentProcessed({ _ in
                pipe(connection, target)
            }))
        }
    }

    private func handleHttpProxy(requestData data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8),
              let urlLine = request.split(separator: "\r\n").first,
              let url = URL(string: String(urlLine.split(separator: " ").dropFirst().first ?? ""))
        else {
            connection.send(content: "HTTP/1.1 400 Bad Request\r\n\r\n".data(using: .utf8), completion: .contentProcessed({ _ in connection.cancel() }))
            return
        }

        let target = NWConnection(host: NWEndpoint.Host(url.host ?? ""), port: NWEndpoint.Port(rawValue: UInt16(url.port ?? (url.scheme == "https" ? 443 : 80))), using: .tcp)
        target.start(queue: .global(qos: .utility))

        target.stateUpdateHandler = { state in
            guard case .ready = state else { return }
            target.send(content: data, completion: .contentProcessed({ _ in
                pipe(connection, target)
            }))
        }
    }

    private func extractTarget(from request: String) -> (host: String, port: UInt16)? {
        let lines = request.split(separator: "\r\n")
        guard let first = lines.first else { return nil }
        let parts = first.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        let hostPort = String(parts[1]).split(separator: ":")
        guard hostPort.count == 2, let port = UInt16(hostPort[1]) else { return nil }
        return (String(hostPort[0]), port)
    }
}

private func pipe(_ a: NWConnection, _ b: NWConnection) {
    readLoop(from: a, to: b)
    readLoop(from: b, to: a)
}

private func readLoop(from source: NWConnection, to target: NWConnection) {
    source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
        if let data = data, !data.isEmpty {
            target.send(content: data, completion: .contentProcessed({ _ in
                guard !isComplete, error == nil else {
                    source.cancel()
                    target.cancel()
                    return
                }
                readLoop(from: source, to: target)
            }))
        } else {
            source.cancel()
            target.cancel()
        }
    }
}
