import SwiftUI

struct DomainList: Identifiable, Codable {
    var id = UUID()
    var name: String
    var domains: [String]

    var summary: String {
        "\(domains.count) доменов"
    }
}

struct DomainListsView: View {
    @State private var lists: [DomainList] = []
    @State private var showAdd = false
    @State private var editList: DomainList?

    var body: some View {
        List {
            if lists.isEmpty {
                Section {
                    Text("Нет списков доменов")
                        .foregroundColor(.gray)
                }
            }

            ForEach($lists) { $list in
                Section(list.name) {
                    Text(list.summary)
                        .foregroundColor(.gray)
                        .font(.caption)

                    ForEach(list.domains, id: \.self) { domain in
                        Text(domain)
                            .font(.system(.body, design: .monospaced))
                    }
                    .onDelete { offsets in
                        list.domains.remove(atOffsets: offsets)
                        save()
                    }

                    Button("Добавить домен") {
                        editList = list
                    }
                }
            }
            .onDelete { indexSet in
                lists.remove(atOffsets: indexSet)
                save()
            }

            Section {
                Button("Добавить список") {
                    showAdd = true
                }
            }

            if !lists.isEmpty {
                Section {
                    Button("Сбросить списки", role: .destructive) {
                        lists = []
                        save()
                    }
                }
            }
        }
        .navigationTitle("Списки")
        .onAppear(perform: load)
        .alert("Добавить домен", isPresented: $showAdd) {
            TextField("Название", text: .constant(""))
            TextField("Домены (каждый с новой строки)", text: .constant(""), axis: .vertical)
            Button("Добавить") {}
            Button("Отмена", role: .cancel) {}
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "domainLists"),
           let decoded = try? JSONDecoder().decode([DomainList].self, from: data) {
            lists = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(data, forKey: "domainLists")
        }
    }
}
