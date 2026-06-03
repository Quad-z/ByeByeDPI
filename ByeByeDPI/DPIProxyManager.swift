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
        case .off: return "Отключено (Прокси)"
        case .loading: return "Запуск..."
        case .on: return "Подключено (Прокси)"
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

        let ud = UserDefaults.standard
        let useCmd = ud.bool(forKey: "byedpi_enable_cmd")

        let args: [String]

        if useCmd {
            let cmdStr = ud.string(forKey: "byedpi_cmd_args") ?? "-o1 -a1 -r-5+se"
            let ip = ud.string(forKey: "byedpi_proxy_ip") ?? "127.0.0.1"
            let port = ud.string(forKey: "byedpi_proxy_port") ?? "1080"
            let parts = cmdStr.split(separator: " ").map(String.init)
            args = ["-i", ip, "-p", port] + parts
        } else {
            args = buildArgsFromUI()
        }

        ByeDPI.start(args: args) { [weak self] error in
            DispatchQueue.main.async {
                self?.state = .off
                if case .startError(let code) = error {
                    self?.errorMessage = "Код ошибки: \(code)"
                } else {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.state == .loading else { return }
            if ByeDPI.proxyStarted {
                self.state = .on
            } else {
                self.state = .off
                self.errorMessage = "Прокси не запустился."
            }
        }
    }

    func stop() {
        _ = ByeDPI.stop()
        state = .off
        errorMessage = nil
    }

    func exportLogs() {
        errorMessage = "Логи пока не реализованы"
    }

    private func buildArgsFromUI() -> [String] {
        let ud = UserDefaults.standard
        let ip = ud.string(forKey: "byedpi_proxy_ip") ?? "127.0.0.1"
        let port = ud.string(forKey: "byedpi_proxy_port") ?? "1080"
        let maxConn = ud.string(forKey: "byedpi_max_connections") ?? "512"
        let bufSize = ud.string(forKey: "byedpi_buffer_size") ?? "16384"
        let defaultTtl = ud.string(forKey: "byedpi_default_ttl") ?? "0"
        let noDomain = ud.bool(forKey: "byedpi_no_domain")
        let desyncMethod = ud.string(forKey: "byedpi_desync_method") ?? "oob"
        let splitPosition = ud.string(forKey: "byedpi_split_position") ?? "1"
        let splitAtHost = ud.bool(forKey: "byedpi_split_at_host")
        let desyncHttp = ud.bool(forKey: "byedpi_desync_http")
        let desyncHttps = ud.bool(forKey: "byedpi_desync_https")
        let desyncUdp = ud.bool(forKey: "byedpi_desync_udp")
        let fakeTtl = ud.string(forKey: "byedpi_fake_ttl") ?? "8"
        let fakeSni = ud.string(forKey: "byedpi_fake_sni") ?? "www.iana.org"
        let fakeOffset = ud.string(forKey: "byedpi_fake_offset") ?? "0"
        let oobData = ud.string(forKey: "byedpi_oob_data") ?? "a"
        let hostMixedCase = ud.bool(forKey: "byedpi_host_mixed_case")
        let domainMixedCase = ud.bool(forKey: "byedpi_domain_mixed_case")
        let hostRemoveSpaces = ud.bool(forKey: "byedpi_host_remove_spaces")
        let tlsrecEnabled = ud.bool(forKey: "byedpi_tlsrec_enabled")
        let tlsrecPosition = ud.string(forKey: "byedpi_tlsrec_position") ?? "0"
        let tlsrecAtSni = ud.bool(forKey: "byedpi_tlsrec_at_sni")
        let tcpFastOpen = ud.bool(forKey: "byedpi_tcp_fast_open")
        let dropSack = ud.bool(forKey: "byedpi_drop_sack")
        let udpFakeCount = ud.string(forKey: "byedpi_udp_fake_count") ?? "1"
        let hostsMode = ud.string(forKey: "byedpi_hosts_mode") ?? "disable"
        let hostsBlacklist = ud.string(forKey: "byedpi_hosts_blacklist") ?? ""
        let hostsWhitelist = ud.string(forKey: "byedpi_hosts_whitelist") ?? ""

        var args: [String] = ["-i", ip, "-p", port, "-c", maxConn, "-b", bufSize]

        if let ttl = Int(defaultTtl), ttl != 0 {
            args.append("-g\(ttl)")
        }
        if noDomain {
            args.append("-N")
        }
        if tcpFastOpen {
            args.append("-F")
        }

        let protocols = [desyncHttps ? "t" : "", desyncHttp ? "h" : ""].filter { !$0.isEmpty }

        switch hostsMode {
        case "blacklist":
            let hosts = hostsBlacklist.replacingOccurrences(of: "\n", with: " ")
            if !hosts.isEmpty {
                args.append("-H:\(hosts)")
                args.append("-An")
                if !protocols.isEmpty { args.append("-K\(protocols.joined(separator: ","))") }
            }
        case "whitelist":
            let hosts = hostsWhitelist.replacingOccurrences(of: "\n", with: " ")
            if !protocols.isEmpty { args.append("-K\(protocols.joined(separator: ","))") }
            if !hosts.isEmpty { args.append("-H:\(hosts)") }
        default:
            if !protocols.isEmpty { args.append("-K\(protocols.joined(separator: ","))") }
        }

        let methodFlag: String
        switch desyncMethod {
        case "split": methodFlag = "s"
        case "disorder": methodFlag = "d"
        case "oob": methodFlag = "o"
        case "disoob": methodFlag = "q"
        case "fake": methodFlag = "f"
        default: methodFlag = ""
        }

        if !methodFlag.isEmpty, let pos = Int(splitPosition), pos != 0 {
            let posStr = pos.description + (splitAtHost ? "+h" : "")
            args.append("-\(methodFlag)\(posStr)")
        }

        if desyncMethod == "fake" {
            if let ttl = Int(fakeTtl), ttl != 0 { args.append("-t\(ttl)") }
            if !fakeSni.isEmpty { args.append("-n\(fakeSni)") }
            if let offset = Int(fakeOffset), offset != 0 { args.append("-O\(offset)") }
        }

        if desyncMethod == "oob" || desyncMethod == "disoob" {
            if let byte = oobData.first?.asciiValue { args.append("-e\(byte)") }
        }

        var modHttp: [String] = []
        if hostMixedCase { modHttp.append("h") }
        if domainMixedCase { modHttp.append("d") }
        if hostRemoveSpaces { modHttp.append("r") }
        if !modHttp.isEmpty { args.append("-M\(modHttp.joined(separator: ","))") }

        if tlsrecEnabled, let pos = Int(tlsrecPosition), pos != 0 {
            let posStr = pos.description + (tlsrecAtSni ? "+s" : "")
            args.append("-r\(posStr)")
        }

        if dropSack { args.append("-Y") }

        args.append("-An")

        if desyncUdp {
            args.append("-Ku")
            if let cnt = Int(udpFakeCount), cnt != 0 { args.append("-a\(cnt)") }
            args.append("-An")
        }

        return args
    }
}
