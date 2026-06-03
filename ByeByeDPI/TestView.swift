import SwiftUI

struct Strategy: Identifiable {
    let id = UUID()
    let args: String
}

extension Strategy {
    static let defaultStrategies: [Strategy] = [
        Strategy(args: "-s1 -d1 -r1+s -a1 -Ar -o1 -a1 -At -r1+s -a1"),
        Strategy(args: "-o1 -a1 -r-5+se"),
        Strategy(args: "-f1 -t8 -nwww.iana.org"),
        Strategy(args: "-s1 -d1 -r1+s -a1"),
        Strategy(args: "-s1 -d2 -r1+s -a1 -Ar -o1 -a1 -At -r1+s -a1"),
        Strategy(args: "-s1 -d1 -r5+s -a3 -Ar -o1 -a1 -At -r1+s -a1"),
    ]
}

struct TestView: View {
    @State private var strategies = Strategy.defaultStrategies
    @State private var copiedIndex: Int?

    var body: some View {
        List {
            Section {
                Text("Нажмите на стратегию, чтобы скопировать. Затем вставьте в Редактор → Использовать командную строку.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Section("Стратегии") {
                ForEach(Array(strategies.enumerated()), id: \.element.id) { index, strategy in
                    Button {
                        UIPasteboard.general.string = strategy.args
                        copiedIndex = index
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if copiedIndex == index { copiedIndex = nil }
                        }
                    } label: {
                        HStack {
                            Text(strategy.args)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(3)
                            Spacer()
                            if copiedIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Подбор")
    }
}
