import SwiftUI

struct EditorView: View {
    @AppStorage("byedpi_enable_cmd") private var useCmd = false
    @AppStorage("byedpi_max_connections") private var maxConn = "512"
    @AppStorage("byedpi_buffer_size") private var bufSize = "16384"
    @AppStorage("byedpi_no_domain") private var noDomain = false
    @AppStorage("byedpi_tcp_fast_open") private var tcpFastOpen = false
    @AppStorage("byedpi_hosts_mode") private var hostsMode = "disable"
    @AppStorage("byedpi_hosts_blacklist") private var hostsBlacklist = ""
    @AppStorage("byedpi_hosts_whitelist") private var hostsWhitelist = ""
    @AppStorage("byedpi_default_ttl") private var defaultTtl = "0"
    @AppStorage("byedpi_desync_method") private var desyncMethod = "oob"
    @AppStorage("byedpi_split_position") private var splitPosition = "1"
    @AppStorage("byedpi_split_at_host") private var splitAtHost = false
    @AppStorage("byedpi_drop_sack") private var dropSack = false
    @AppStorage("byedpi_fake_ttl") private var fakeTtl = "8"
    @AppStorage("byedpi_fake_offset") private var fakeOffset = "0"
    @AppStorage("byedpi_fake_sni") private var fakeSni = "www.iana.org"
    @AppStorage("byedpi_oob_data") private var oobData = "a"
    @AppStorage("byedpi_desync_http") private var desyncHttp = true
    @AppStorage("byedpi_desync_https") private var desyncHttps = true
    @AppStorage("byedpi_desync_udp") private var desyncUdp = true
    @AppStorage("byedpi_host_mixed_case") private var hostMixedCase = false
    @AppStorage("byedpi_domain_mixed_case") private var domainMixedCase = false
    @AppStorage("byedpi_host_remove_spaces") private var hostRemoveSpaces = false
    @AppStorage("byedpi_tlsrec_enabled") private var tlsrecEnabled = false
    @AppStorage("byedpi_tlsrec_position") private var tlsrecPosition = "0"
    @AppStorage("byedpi_tlsrec_at_sni") private var tlsrecAtSni = false
    @AppStorage("byedpi_udp_fake_count") private var udpFakeCount = "1"
    @AppStorage("byedpi_cmd_args") private var cmdArgs = "-o1 -a1 -r-5+se"

    var body: some View {
        List {
            Toggle("Использовать командную строку", isOn: $useCmd)

            if useCmd {
                cmdEditorSection
            } else {
                uiEditorSections
            }
        }
        .navigationTitle("Редактор")
    }

    private var cmdEditorSection: some View {
        Section("Аргументы командной строки") {
            TextField("byedpi args", text: $cmdArgs, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .lineLimit(5...10)
        }
    }

    private var uiEditorSections: some View {
        Group {
            Section("Прокси") {
                                HStack {
                    Text("Макс. подключений")
                    Spacer()
                    TextField("512", text: $maxConn)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Размер буфера")
                    Spacer()
                    TextField("16384", text: $bufSize)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                }
                Toggle("Без домена", isOn: $noDomain)
                Toggle("TCP Fast Open", isOn: $tcpFastOpen)
            }

            Section("Десинхронизация") {
                Picker("Метод", selection: $desyncMethod) {
                    Text("None").tag("none")
                    Text("Split").tag("split")
                    Text("Disorder").tag("disorder")
                    Text("Fake").tag("fake")
                    Text("OOB").tag("oob")
                    Text("DISOOB").tag("disoob")
                }

                if desyncMethod != "none" {
                    HStack {
                        Text("Позиция разделения")
                        Spacer()
                        TextField("1", text: $splitPosition)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    Toggle("Разделить в хосте", isOn: $splitAtHost)
                }

                if desyncMethod == "fake" {
                    HStack {
                        Text("TTL поддельных")
                        Spacer()
                        TextField("8", text: $fakeTtl)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Смещение поддельных")
                        Spacer()
                        TextField("0", text: $fakeOffset)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("SNI поддельного пакета")
                        Spacer()
                        TextField("www.iana.org", text: $fakeSni)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                }

                if desyncMethod == "oob" || desyncMethod == "disoob" {
                    HStack {
                        Text("OOB Данные")
                        Spacer()
                        TextField("a", text: $oobData)
                            .frame(width: 40)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                }

                Toggle("Отбрасывать SACK", isOn: $dropSack)
            }

            Section {
                Picker("Хосты", selection: $hostsMode) {
                    Text("Отключено").tag("disable")
                    Text("Чёрный список").tag("blacklist")
                    Text("Белый список").tag("whitelist")
                }

                if hostsMode == "blacklist" {
                    VStack(alignment: .leading) {
                        Text("Чёрный список хостов").font(.caption).foregroundColor(.gray)
                        TextEditor(text: $hostsBlacklist)
                            .frame(minHeight: 80)
                            .font(.system(.body, design: .monospaced))
                    }
                }

                if hostsMode == "whitelist" {
                    VStack(alignment: .leading) {
                        Text("Белый список хостов").font(.caption).foregroundColor(.gray)
                        TextEditor(text: $hostsWhitelist)
                            .frame(minHeight: 80)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            Section("Протоколы") {
                Toggle("HTTP", isOn: $desyncHttp)
                Toggle("HTTPS", isOn: $desyncHttps)
                Toggle("UDP", isOn: $desyncUdp)
            }

            Section("HTTP") {
                Toggle("Смешанный регистр хоста", isOn: $hostMixedCase)
                Toggle("Смешанный регистр домена", isOn: $domainMixedCase)
                Toggle("Удалить пробелы из хоста", isOn: $hostRemoveSpaces)
            }

            Section("HTTPS") {
                Toggle("Разделить TLS запись", isOn: $tlsrecEnabled)
                if tlsrecEnabled {
                    HStack {
                        Text("Позиция разделения")
                        Spacer()
                        TextField("0", text: $tlsrecPosition)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                    Toggle("Разделить в SNI", isOn: $tlsrecAtSni)
                }
            }

            if desyncUdp {
                Section("UDP") {
                    HStack {
                        Text("Кол-во поддельных UDP")
                        Spacer()
                        TextField("1", text: $udpFakeCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
