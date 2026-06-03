import SwiftUI

struct DomainGroup: Identifiable, Codable {
    var id: String
    var name: String
    var domains: [String]
    var isActive: Bool = true
    var isBuiltIn: Bool = false
    var isDeleted: Bool = false

    var domainCount: Int { domains.count }
}

struct DomainListsView: View {
    @State private var lists: [DomainGroup] = []
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newDomains = ""
    @State private var editItem: DomainGroup?
    @State private var editDomains = ""
    @State private var showEdit = false

    private let defaults = UserDefaults.standard

    var body: some View {
        List {
            if lists.isEmpty {
                Section {
                    Text("Нет списков доменов")
                        .foregroundColor(.gray)
                }
            }

            ForEach($lists) { $group in
                if !group.isDeleted {
                    Section {
                        Toggle(isOn: $group.isActive) {
                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                Text("\(group.domainCount) доменов")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onChange(of: group.isActive) { _ in save() }

                        if group.isActive {
                            ForEach(group.domains, id: \.self) { domain in
                                Text(domain)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }

                        HStack {
                            Button("Редактировать") {
                                editItem = group
                                editDomains = group.domains.joined(separator: "\n")
                                showEdit = true
                            }
                            .foregroundColor(.blue)

                            Spacer()

                            Button("Удалить", role: .destructive) {
                                deleteList(id: group.id)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Добавить список") { showAdd = true }
                Button("Сбросить списки", role: .destructive) { resetLists() }
            }
        }
        .navigationTitle("Списки")
        .onAppear(perform: load)
        .alert("Добавить список", isPresented: $showAdd) {
            TextField("Название", text: $newName)
            TextField("Домены (каждый с новой строки)", text: $newDomains, axis: .vertical)
                .lineLimit(5...10)
            Button("Добавить") { addList() }
            Button("Отмена", role: .cancel) {}
        }
        .alert("Редактировать список", isPresented: $showEdit) {
            TextField("Домены", text: $editDomains, axis: .vertical)
                .lineLimit(5...10)
            Button("Сохранить") { updateList() }
            Button("Отмена", role: .cancel) {}
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: "domainLists"),
              let decoded = try? JSONDecoder().decode([DomainGroup].self, from: data) else {
            loadBuiltins()
            return
        }
        lists = decoded
        syncBuiltins()
    }

    private func loadBuiltins() {
        lists = BuiltinData.domainGroups
        save()
    }

    private func syncBuiltins() {
        for builtin in BuiltinData.domainGroups {
            if !lists.contains(where: { $0.id == builtin.id }) {
                lists.append(builtin)
            }
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(lists) {
            defaults.set(data, forKey: "domainLists")
        }
    }

    private func addList() {
        let id = newName.lowercased().replacingOccurrences(of: " ", with: "_")
        guard !id.isEmpty else { return }
        let domains = newDomains.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !domains.isEmpty else { return }
        lists.append(DomainGroup(id: id, name: newName, domains: domains, isBuiltIn: false))
        newName = ""
        newDomains = ""
        save()
    }

    private func updateList() {
        guard let item = editItem, let idx = lists.firstIndex(where: { $0.id == item.id }) else { return }
        let domains = editDomains.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        lists[idx].domains = domains
        editItem = nil
        save()
    }

    private func deleteList(id: String) {
        if let idx = lists.firstIndex(where: { $0.id == id }) {
            if lists[idx].isBuiltIn {
                lists[idx].isDeleted = true
                lists[idx].isActive = false
            } else {
                lists.remove(at: idx)
            }
            save()
        }
    }

    private func resetLists() {
        lists = BuiltinData.domainGroups
        save()
    }
}

struct BuiltinData {
    static let strategies: [String] = [
        "-l:\"\\xC2\\x00\\x00\\x00\\x01\\x14\\x2E\\xE3\\xE3\\x5F\\x6B\\xBB\\x23\\xA8\\xE6\\x5D\\xA9\\x78\\x21\\xCF\\xC2\\x72\\x4C\\x8F\\xC4\\x5E\\x14\\x00\\x00\\x00\\x00\\xC5\\x00\\x00\\x00\\x00\\x4C\\x00\\xA7\\x00\\x00\\x00\\x00\\x00\\x00\\x44\\x00\\x00\\x80\\x00\\x00\\x00\\x0D\\xFC\\xFA\\x1D\\xCD\\x73\\xBA\\x2A\\x90\\x93\\xB3\\xEE\\xF7\\x43\\xC5\\x85\\xDA\\xFF\\x45\\x3C\\x00\\x00\\x00\\x00\\x00\\x00\\x7C\\x00\\x9B\\x00\\xF6\\x00\\x00\\xDD\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x59\\xA8\\xE4\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x7B\\x00\\x0F\\x00\\x00\\x00\\x48\\x4E\\x00\\x00\\x00\\x06\\xF3\\x00\\x00\\x00\\x00\\xD9\\x5A\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\" -a3 -t12 -d1 -s0+h -d3+s -s6+s -d5+s -s8+s -d7+s -s10+s -d3 -At,s -r3",
        "-f-200 -Qr -s3:5+sm -a1 -As -d1 -s4+sm -s8+sh -f-300 -d6+sh -a1 -At,r,s -o2 -f-30 -As -r5 -Mh -r6+sh -f-250 -s2:7+s -s3:6+sm -a1 -At,r,s -s3:5+sm -s6+s -s7:9+s -q30+sm -a1",
        "-s1 -d1 -r1+s -a1 -Ar -o1 -a1 -At -r1+s -a1",
        "-o1 -a1 -r-5+se",
        "-f1 -t8 -nwww.iana.org",
        "-d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -r1+s -S -a1 -As -d1 -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -S -a1",
        "-Ku -l:\"\\xe3\\x00\\x06\\xec\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\" -a3 -An -f64+se -n google.com -t5",
        "-o1 -d1 -a1 -At,r,s -s1 -d1 -s5+s -s10+s -s15+s -s20+s -r1+s -S -a1 -As -s1 -d1 -s5+s -s10+s -s15+s -s20+s -S -a1",
        "-n google.com -Qr -f-204 -s1:5+sm -a1 -As -d1 -s3+s -s5+s -q7 -a1 -As -o2 -f-43 -a1 -As -r5 -Mh -s1:5+s -s3:7+sm -a1",
        "-n google.com -Qr -f-205 -a1 -As -s1:3+sm -a1 -As -s5:8+sm -a1 -As -d3 -q7 -o2 -f-43 -f-85 -f-165 -r5 -Mh -a1",
        "-d1+s -s50+s -a1 -As -f20 -r2+s -a1 -At -d2 -s1+s -s5+s -s10+s -s15+s -s25+s -s35+s -s50+s -s60+s -a1",
        "-o1 -a1 -At,r,s -f-1 -a1 -At,r,s -d1:11+sm -S -a1 -At,r,s -n google.com -Qr -f1 -d1:11+sm -s1:11+sm -S -a1",
        "-d1 -s1 -q1 -Y -a1 -Ar -s5 -o1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1",
        "-f1+nme -t6 -a1 -As -n google.com -Qr -s1:6+sm -a1 -As -s5:12+sm -a1 -As -d3 -q7 -r6 -Mh -a1",
        "-s1 -o1 -a1 -Y -Ar -s5 -o1+s -a1 -At -f-1 -r1+s -a1 -As -s1 -o1+s -s-1 -a1",
        "-s1 -d1 -a1 -Y -Ar -d5 -o1+s -a1 -At -f-1 -r1+s -a1 -As -d1 -o1+s -s-1 -a1",
        "-d1 -s1+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -a1",
        "-s1 -q1 -a1 -Y -Ar -a1 -s5 -o2 -At -f-1 -r1+s -a1 -As -s1 -o1+s -s-1 -a1",
        "-s1 -q1 -a1 -Ar -s5 -o1+s -a1 -At -f-1 -d1+s -a1 -As -s1 -o1+s -s-1 -a1",
        "-s1 -q1 -a1 -Ar -s5 -o2 -a1 -At -f-1 -r1+s -a1 -As -s1 -o1+s -s-1 -a1",
    ]

    static let domainGroups: [DomainGroup] = [
        DomainGroup(id: "general", name: "General", domains: ["rutracker.org", "nyaa.si", "rutor.org", "nnmclub.to", "speedtest.net", "ookla.com"], isActive: false, isBuiltIn: true),
        DomainGroup(id: "cloudflare", name: "Cloudflare", domains: ["cloudflare.com", "1.1.1.1", "dns.google"], isActive: false, isBuiltIn: true),
        DomainGroup(id: "telegram", name: "Telegram", domains: ["telegram.org", "core.telegram.org", "web.telegram.org", "webk.telegram.org", "my.telegram.org", "api.telegram.org", "desktop.telegram.org", "cdn.telegram.org", "telegram.me", "telegra.ph", "telesco.pe", "fragment.telegram.org"], isActive: false, isBuiltIn: true),
        DomainGroup(id: "youtube", name: "YouTube", domains: ["youtube.com", "youtu.be", "i.ytimg.com", "i9.ytimg.com", "yt3.ggpht.com", "googleapis.com", "googleusercontent.com", "yt3.googleusercontent.com"], isActive: true, isBuiltIn: true),
        DomainGroup(id: "discord", name: "Discord", domains: ["discord.com", "discord.gg", "discordapp.com", "discordcdn.com", "discord.media", "discord.store", "discord.gift", "discordmerch.com"], isActive: false, isBuiltIn: true),
        DomainGroup(id: "googlevideo", name: "GoogleVideo", domains: ["rr1---sn-4axm-n8vs.googlevideo.com", "rr1---sn-gvnuxaxjvh-o8ge.googlevideo.com", "rr5---sn-n8v7knez.googlevideo.com", "rr1---sn-u5uuxaxjvhg0-ocje.googlevideo.com", "manifest.googlevideo.com"], isActive: false, isBuiltIn: true),
    ]
}
