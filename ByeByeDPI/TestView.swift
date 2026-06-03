import SwiftUI

struct TestView: View {
    @State private var strategies = Strategy.defaultStrategies
    @State private var results: [StrategyResult] = []
    @State private var isTesting = false
    @State private var logs: [String] = []

    var body: some View {
        List {
            Section {
                if isTesting {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Тестирование...")
                            .foregroundColor(.yellow)
                            .padding(.leading, 8)
                    }
                } else {
                    Button("Начать проверку") {
                        startTest()
                    }
                }
            }

            if !results.isEmpty {
                Section("Результаты") {
                    ForEach(results.sorted { $0.successCount > $1.successCount }) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.strategy.args)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(result.successCount > 0 ? .green : .red)
                            HStack {
                                Text("✅ \(result.successCount)/\(result.totalCount)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                if result.isBest {
                                    Text("★ Лучшая")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !logs.isEmpty {
                Section("Лог") {
                    ForEach(logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Подбор")
    }

    private func startTest() {
        results = []
        logs = []
        isTesting = true

        DispatchQueue.global().async {
            let testDomains = ["google.com", "youtube.com", "telegram.org", "github.com"]

            for strategy in self.strategies {
                var success = 0

                for domain in testDomains {
                    if !self.isTesting { break }

                    let args = strategy.parseToArgs()
                    if self.testDomain(domain, with: args) {
                        success += 1
                    }

                    Thread.sleep(forTimeInterval: 0.5)
                }

                if !self.isTesting { break }

                DispatchQueue.main.async {
                    self.logs.append("\(strategy.args) — \(success)/\(testDomains.count)")
                    self.results.append(StrategyResult(strategy: strategy, successCount: success, totalCount: testDomains.count))
                }
            }

            DispatchQueue.main.async {
                self.isTesting = false
                if let best = self.results.max(by: { $0.successCount < $1.successCount }) {
                    self.logs.append("Лучшая: \(best.strategy.args)")
                }
            }
        }
    }

    private func testDomain(_ domain: String, with args: [String]) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var ok = false

        let config = URLSessionConfiguration.ephemeral
        config.connectionProxyDictionary = [
            kCFNetworkProxiesSOCKSEnable: true,
            kCFNetworkProxiesSOCKSProxy: "127.0.0.1",
            kCFNetworkProxiesSOCKSPort: 1080,
        ]
        config.timeoutIntervalForRequest = 5

        let task = URLSession(configuration: config).dataTask(with: URL(string: "https://\(domain)")!) { _, resp, _ in
            if let httpResp = resp as? HTTPURLResponse, (200...399).contains(httpResp.statusCode) {
                ok = true
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)

        return ok
    }
}

struct Strategy: Identifiable {
    let id = UUID()
    let args: String

    static let defaultStrategies: [Strategy] = [
        Strategy(args: "-s1 -d1 -r1+s -a1 -Ar -o1 -a1 -At -r1+s -a1"),
        Strategy(args: "-o1 -a1 -r-5+se"),
        Strategy(args: "-f1 -t8 -nwww.iana.org"),
        Strategy(args: "-s1 -d1 -r1+s -a1"),
    ]

    func parseToArgs() -> [String] {
        args.split(separator: " ").map(String.init)
    }
}

struct StrategyResult: Identifiable {
    let id = UUID()
    let strategy: Strategy
    let successCount: Int
    let totalCount: Int

    var isBest: Bool { false }
}
