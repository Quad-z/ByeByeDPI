import SwiftUI
import ByeDPIKit

struct StrategyResultItem: Identifiable {
    let id = UUID()
    let command: String
    var successCount = 0
    var totalRequests = 0
    var siteResults: [SiteResultItem] = []
    var isCompleted = false
    var isBest = false
}

struct SiteResultItem: Identifiable {
    let id = UUID()
    let site: String
    let successCount: Int
    let totalCount: Int
}

struct TestView: View {
    @AppStorage("byedpi_proxy_ip") private var proxyIP = "127.0.0.1"
    @AppStorage("byedpi_proxy_port") private var proxyPort = "1050"

    @State private var strategies: [StrategyResultItem] = []
    @State private var isTesting = false
    @State private var progressText = ""
    @State private var testLog: [String] = []
    @State private var showLog = false

    private let defaults = UserDefaults.standard

    var activeDomains: [String] {
        guard let data = defaults.data(forKey: "domainLists"),
              let lists = try? JSONDecoder().decode([DomainGroup].self, from: data) else {
            return BuiltinData.domainGroups.filter { $0.isActive }.flatMap { $0.domains }
        }
        let active = lists.filter { $0.isActive && !$0.isDeleted }
        return active.isEmpty ? BuiltinData.domainGroups.filter { $0.isActive }.flatMap { $0.domains } : active.flatMap { $0.domains }
    }

    var body: some View {
        List {
            Section {
                if isTesting {
                    HStack {
                        ProgressView().tint(.white)
                        Text(progressText)
                            .foregroundColor(.yellow)
                            .padding(.leading, 8)
                    }
                } else {
                    Button("Начать проверку") { startTest() }
                }
            }

            if !strategies.isEmpty {
                Section("Результаты") {
                    ForEach(Array(strategies.enumerated()), id: \.element.id) { _, strategy in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(strategy.command)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(3)
                                    .foregroundColor(strategy.isCompleted ? (strategy.successCount > 0 ? .green : .red) : .white)
                                Spacer()
                                if strategy.isBest {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }

                            if strategy.isCompleted {
                                HStack {
                                    Text("✅ \(strategy.successCount)/\(strategy.totalRequests)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Button("Копировать") {
                                        UIPasteboard.general.string = strategy.command
                                    }
                                    .font(.caption)
                                    if strategy.successCount > 0 {
                                        Button("Применить") {
                                            applyStrategy(strategy.command)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }

                                if !strategy.siteResults.isEmpty {
                                    DisclosureGroup("Детали") {
                                        ForEach(strategy.siteResults) { site in
                                            HStack {
                                                Text(site.site).font(.caption)
                                                Spacer()
                                                Text("\(site.successCount)/\(site.totalCount)")
                                                    .font(.caption)
                                                    .foregroundColor(site.successCount > 0 ? .green : .red)
                                            }
                                        }
                                    }
                                }
                            } else if isTesting {
                                HStack {
                                    ProgressView().scaleEffect(0.7)
                                    Text("Тестируется...").font(.caption).foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !testLog.isEmpty {
                Section {
                    Button(showLog ? "Скрыть лог" : "Показать лог") {
                        withAnimation { showLog.toggle() }
                    }
                    if showLog {
                        ForEach(testLog, id: \.self) { line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Подбор")
    }

    private func startTest() {
        let domains = activeDomains
        guard !domains.isEmpty else { return }

        let cmds = defaults.string(forKey: "byedpi_proxytest_commands")?
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? BuiltinData.strategies

        strategies = cmds.map { StrategyResultItem(command: $0) }
        isTesting = true
        testLog = []

        let savedCmd = defaults.string(forKey: "byedpi_cmd_args") ?? ""

        DispatchQueue.global().async {
            let mgr = DPIProxyManager.shared

            for (i, cmd) in cmds.enumerated() {
                guard isTesting else { break }

                DispatchQueue.main.sync { progressText = "Проверка \(i + 1)/\(cmds.count)" }

                defaults.set(cmd, forKey: "byedpi_cmd_args")

                let started = restartProxy(mgr)
                guard started else {
                    DispatchQueue.main.sync {
                        strategies[i].isCompleted = true
                        strategies[i].totalRequests = domains.count
                        testLog.append("\(cmd) — прокси не запустился")
                    }
                    continue
                }

                testDomains(domains, for: i, mgr: mgr)
            }

            defaults.set(savedCmd, forKey: "byedpi_cmd_args")

            DispatchQueue.main.sync {
                isTesting = false
                progressText = "Проверка завершена"
            }
        }
    }

    private func restartProxy(_ mgr: DPIProxyManager) -> Bool {
        let sem = DispatchSemaphore(value: 0)
        var started = false

        DispatchQueue.main.sync {
            if mgr.state == .on { mgr.stop() }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mgr.start()

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    started = ByeDPI.proxyStarted
                    sem.signal()
                }
            }
        }

        _ = sem.wait(timeout: .now() + 6)
        return started
    }

    private func testDomains(_ domains: [String], for index: Int, mgr: DPIProxyManager) {
        let port = Int(proxyPort) ?? 1050
        var successCount = 0
        var siteResults: [SiteResultItem] = []

        for domain in domains {
            guard isTesting else { break }

            DispatchQueue.main.sync { progressText = "\(domain)" }

            let sem = DispatchSemaphore(value: 0)
            var ok = false

            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 5
            config.timeoutIntervalForResource = 8
            config.connectionProxyDictionary = [
                "SOCKSEnable": true,
                "SOCKSProxy": proxyIP,
                "SOCKSPort": port,
            ]

            let task = URLSession(configuration: config).dataTask(with: URL(string: "https://\(domain)")!) { _, resp, _ in
                if let httpResp = resp as? HTTPURLResponse, (200...399).contains(httpResp.statusCode) {
                    ok = true
                }
                sem.signal()
            }
            task.resume()
            _ = sem.wait(timeout: .now() + 6)

            if ok { successCount += 1 }
            siteResults.append(SiteResultItem(site: domain, successCount: ok ? 1 : 0, totalCount: 1))
        }

        DispatchQueue.main.sync {
            strategies[index].successCount = successCount
            strategies[index].totalRequests = domains.count
            strategies[index].siteResults = siteResults
            strategies[index].isCompleted = true
            testLog.append("\(strategies[index].command) — \(successCount)/\(domains.count)")

            let best = strategies.filter { $0.isCompleted }.max { $0.successCount < $1.successCount }
            for i in strategies.indices {
                strategies[i].isBest = strategies[i].id == best?.id && (best?.successCount ?? 0) > 0
            }
        }

        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            mgr.stop()
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 3)
    }

    private func applyStrategy(_ command: String) {
        defaults.set(command, forKey: "byedpi_cmd_args")
        progressText = "Применена"
    }
}
