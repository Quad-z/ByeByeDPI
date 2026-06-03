import SwiftUI

struct ContentView: View {
    @StateObject private var proxy = DPIProxyManager.shared
    @State private var showEditor = false
    @State private var showSettings = false
    @State private var showTest = false
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
                            Button("Сохранить логи") { proxy.exportLogs() }
                            Button("Закрыть приложение") { exit(0) }
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
                                    .shadow(color: proxy.state == .on ? .green.opacity(0.4) : .clear, radius: 20)
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

                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            TileButton(icon: "slider.horizontal.3", title: "Редактор", action: { showEditor = true })
                            TileButton(icon: "gearshape.fill", title: "Настройки", action: { showSettings = true })
                        }
                        HStack(spacing: 16) {
                            TileButton(icon: "gauge.medium", title: "Подбор", action: { showTest = true })
                            TileButton(icon: "list.bullet", title: "Списки", action: { showLists = true })
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showEditor) { EditorView() }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(isPresented: $showTest) { TestView() }
            .navigationDestination(isPresented: $showLists) { DomainListsView() }
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

struct TileButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .buttonStyle(PlainButtonStyle())
    }
}
