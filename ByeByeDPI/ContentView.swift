import SwiftUI

struct ContentView: View {
    @StateObject private var proxy = LocalProxyManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("ByeByeDPI")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Menu {
                        Button("О приложении", action: {})
                        Button("Экспорт логов", action: {})
                        Button("Выйти", action: {})
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
                    Button(action: { proxy.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(proxy.isRunning ? Color.green : Color(.sRGB, white: 0.15, opacity: 1))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Circle()
                                        .stroke(proxy.isRunning ? Color.green.opacity(0.4) : Color(.sRGB, white: 0.25, opacity: 1), lineWidth: 4)
                                )
                            Image(systemName: "power")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(proxy.isRunning ? .white : .gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(proxy.isRunning ? "Активен (Прокси)" : "Остановлен")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(proxy.isRunning ? .green : .white)

                    Text("127.0.0.1:1080")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    FeatureTile(icon: "slider.horizontal.3", title: "Редактор")
                    FeatureTile(icon: "gearshape.fill", title: "Настройки")
                    FeatureTile(icon: "gauge.medium", title: "Подбор")
                    FeatureTile(icon: "list.bullet", title: "Списки")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
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
