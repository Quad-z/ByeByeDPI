import Foundation
import ByeDPIKit

final class DPIProxyManager: ObservableObject {
    static let shared = DPIProxyManager()

    @Published var isRunning = false

    private init() {}

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard !ByeDPI.proxyStarted else { return }

        let args = [
            "byedpi",
            "--socks", "127.0.0.1:1080",
            "--fake",
            "--split", "2",
            "--tls",
            "--http",
            "--md5sig",
        ]

        ByeDPI.start(args: args) { [weak self] error in
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if ByeDPI.proxyStarted {
                self?.isRunning = true
            }
        }
    }

    func stop() {
        ByeDPI.forceStop()
        isRunning = false
    }
}
