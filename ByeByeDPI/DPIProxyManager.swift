import Foundation
import SwiftUI
import ByeDPIKit

enum ProxyState: Equatable {
    case off
    case loading
    case on

    var color: Color {
        switch self {
        case .off: return Color(.sRGB, white: 0.15, opacity: 1)
        case .loading: return Color.yellow
        case .on: return Color.green
        }
    }

    var statusText: String {
        switch self {
        case .off: return "Остановлен"
        case .loading: return "Запуск..."
        case .on: return "Активен (Прокси)"
        }
    }

    var textColor: Color {
        switch self {
        case .off: return .white
        case .loading: return .yellow
        case .on: return .green
        }
    }
}

final class DPIProxyManager: ObservableObject {
    static let shared = DPIProxyManager()

    @Published private(set) var state: ProxyState = .off
    @Published var errorMessage: String?

    private var startTime: Date?

    private init() {}

    func toggle() {
        if state == .on {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard state != .loading else { return }
        state = .loading
        errorMessage = nil

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
                self?.state = .off
                self?.errorMessage = "Ошибка запуска: \(error.localizedDescription)"
            }
        }

        startTime = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, self.state == .loading else { return }
            if ByeDPI.proxyStarted {
                self.state = .on
            } else {
                self.state = .off
                self.errorMessage = "Прокси не запустился. Попробуйте ещё раз."
            }
        }
    }

    func stop() {
        ByeDPI.forceStop()
        state = .off
        errorMessage = nil
    }

    func exportLogs() {
        errorMessage = "Логи пока не реализованы"
    }
}
