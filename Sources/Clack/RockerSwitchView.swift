import SwiftUI

struct RockerSwitchView: View {
    let isOn: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            Circle()
                .fill(isOn ? Color.red.opacity(0.8) : Color.white.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .overlay(
                    Text(isOn ? "I" : "O")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(isOn ? 0.9 : 0.7))
                )
        }
        .frame(width: 44, height: 44)
    }
}
