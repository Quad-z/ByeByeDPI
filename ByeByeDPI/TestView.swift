import SwiftUI

struct Strategy: Identifiable {
    let id = UUID()
    let args: String

    static let defaultStrategies: [Strategy] = [
        Strategy(args: "-s1 -d1 -r1+s -a1 -Ar -o1 -a1 -At -r1+s -a1"),
        Strategy(args: "-o1 -a1 -r-5+se"),
        Strategy(args: "-f1 -t8 -nwww.iana.org"),
        Strategy(args: "-s1 -d1 -r1+s -a1"),
    ]
}

struct TestView: View {
    @State private var strategies = Strategy.defaultStrategies
    @State private var selectedArgs = ""
    @State private var showCopied = false

    var body: some View {
        List {
            Section {
                Text("Нажмите на стратегию, чтобы применить её")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section("Стратегии") {
                ForEach(strategies) { strategy in
                    Button {
                        UIPasteboard.general.string = strategy.args
                        selectedArgs = strategy.args
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    } label: {
                        HStack {
                            Text(strategy.args)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Spacer()
                            if showCopied && selectedArgs == strategy.args {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Подбор")
    }
}
