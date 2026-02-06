import SwiftUI

struct KnobView: View {
    let title: String
    @Binding var value: Double

    @State private var startValue: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    .frame(width: 56, height: 56)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 16)
                    .offset(y: -16)
                    .rotationEffect(Angle(degrees: knobAngle))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let delta = Double(-value.translation.height / 120.0)
                        let next = max(0, min(100, startValue + delta * 100))
                        self.value = next
                    }
                    .onEnded { _ in
                        startValue = self.value
                    }
            )
            .onAppear {
                startValue = value
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 90)
    }

    private var knobAngle: Double {
        let minAngle = -135.0
        let maxAngle = 135.0
        let t = value / 100.0
        return minAngle + (maxAngle - minAngle) * t
    }
}
