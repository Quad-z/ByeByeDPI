import SwiftUI

struct ContentView: View {
    @StateObject private var proxy = DPIProxyManager.shared
    @State private var showEditor = false
    @State private var showSettings = false
    @State private var showPicker = false
    @State private var showLists = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("ByeByeDPI")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Menu {
                            Button("О приложении") {
                                alertMessage = "ByeByeDPI v1.0\nОбход DPI на основе byedpi"
                                showAlert = true
                            }
                            Button("Экспорт логов") { proxy.exportLogs() }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color(.sRGB, white: 0.15, opacity: 1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                    Spacer()

                    VStack(spacing: 16) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            proxy.toggle()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(proxy.state.color)
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Circle()
                                            .stroke(proxy.state == .loading ? Color.yellow.opacity(0.6) : proxy.state.color.opacity(0.4), lineWidth: 4)
                                    )
                                if proxy.state == .loading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(2)
                                } else {
                                    Image(systemName: "power")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(proxy.state == .off ? .gray : .white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(proxy.state == .loading)

                        Text(proxy.state.statusText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(proxy.state.textColor)

                        Text("127.0.0.1:1080")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        FeatureTile(icon: "slider.horizontal.3", title: "Редактор")
                            .onTapGesture { showEditor = true }
                        FeatureTile(icon: "gearshape.fill", title: "Настройки")
                            .onTapGesture { showSettings = true }
                        FeatureTile(icon: "gauge.medium", title: "Подбор")
                            .onTapGesture { showPicker = true }
                        FeatureTile(icon: "list.bullet", title: "Списки")
                            .onTapGesture { showLists = true }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showEditor) { EditorView() }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: $showPicker) { PickerView() }
            .navigationDestination(isPresented: $showLists) { ListsView() }
            .alert("ByeByeDPI", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onChange(of: proxy.errorMessage) { msg in
                guard let msg = msg else { return }
                alertMessage = msg
                showAlert = true
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct FeatureTile: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(.sRGB, white: 0.12, opacity: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Placeholder views for tiles

struct EditorView: View {
    var body: some View {
        List {
            Section("Параметры ByeDPI") {
                Text("--socks 127.0.0.1:1080")
                Text("--fake")
                Text("--split 2")
                Text("--tls")
                Text("--http")
                Text("--md5sig")
            }
        }
        .navigationTitle("Редактор")
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("Прокси") {
                HStack {
                    Text("Адрес")
                    Spacer()
                    Text("127.0.0.1:1080").foregroundColor(.gray)
                }
                HStack {
                    Text("Протокол")
                    Spacer()
                    Text("SOCKS5").foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Настройки")
    }
}

struct PickerView: View {
    var body: some View {
        List {
            Section("Стратегия обхода") {
                Text("По умолчанию")
                Text("fake + split + tls + http + md5sig")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Подбор")
    }
}

struct ListsView: View {
    var body: some View {
        List {
            Section("Списки доменов") {
                Text("Список не загружен")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Списки")
    }
}
