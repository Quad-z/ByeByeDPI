import SwiftUI

struct SettingsView: View {
    @AppStorage("byedpi_proxy_ip") private var proxyIP = "127.0.0.1"
    @AppStorage("byedpi_proxy_port") private var proxyPort = "1080"
    @AppStorage("auto_connect") private var autoConnect = false
    @AppStorage("app_theme") private var theme = "system"

    var body: some View {
        List {
            Section("Общие") {
                Picker("Тема", selection: $theme) {
                    Text("Системная").tag("system")
                    Text("Тёмная").tag("dark")
                    Text("Светлая").tag("light")
                }
            }

            Section("Автоматизация") {
                Toggle("Автоподключение при открытии", isOn: $autoConnect)
            }

            Section("Прокси") {
                HStack {
                    Text("IP")
                    Spacer()
                    TextField("127.0.0.1", text: $proxyIP)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                HStack {
                    Text("Порт")
                    Spacer()
                    TextField("1080", text: $proxyPort)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                }
            }

            Section("О программе") {
                HStack {
                    Text("Версия")
                    Spacer()
                    Text("1.0.0").foregroundColor(.gray)
                }
                HStack {
                    Text("ByeDPI")
                    Spacer()
                    Text("0.17.3 (ba53229)").foregroundColor(.gray)
                }
                Link("Документация", destination: URL(string: "https://github.com/BDManual/ByeByeDPI-Manual")!)
                Link("Исходный код", destination: URL(string: "https://github.com/Quad-z/ByeByeDPI")!)
            }
        }
        .navigationTitle("Настройки")
    }
}
