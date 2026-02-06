import SwiftUI

struct ClackMenuView: View {
    @ObservedObject var model: AppModel
    @State private var isScaleExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            headerRow

            scaleRow

            knobRow

            instrumentRow
        }
        .padding(16)
        .frame(width: 270)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
                .opacity(0.92)
        )
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Button(action: {
                model.toggleEnabled()
            }) {
                RockerSwitchView(isOn: model.isEnabled)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.isEnabled ? "Disable Clack" : "Enable Clack")

            Spacer()

            Menu {
                Text(model.captureStatus)
                if !model.captureDetail.isEmpty {
                    Text(model.captureDetail)
                }
                Text("Capture Mode: \(model.captureMode)")
                Text("Accessibility: \(model.accessibilityStatus)")
                Text("Input Monitoring: \(model.inputMonitoringStatus)")
                Divider()
                Text("On/Off Shortcut: ⌥⌘T")
                    .font(.footnote)
                Divider()
                Button("Open Accessibility Settings") {
                    model.openAccessibilitySettings()
                }
                Button("Open Input Monitoring Settings") {
                    model.openInputMonitoringSettings()
                }
                Button("Refresh Permission Status") {
                    model.refreshPermissionStatus()
                }
                Divider()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var scaleRow: some View {
        VStack(spacing: 6) {
            DisclosureGroup(isExpanded: $isScaleExpanded) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Key")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            ForEach(KeyNote.allCases) { key in
                                Button(key.displayName) {
                                    model.selectedKey = key
                                }
                            }
                        } label: {
                            Text(model.selectedKey.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(minWidth: 60, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .menuStyle(.borderlessButton)
                    }

                    HStack {
                        Text("Scale")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            ForEach(ScaleType.allCases) { scale in
                                Button(scale.displayName) {
                                    model.selectedScale = scale
                                }
                            }
                        } label: {
                            Text(model.selectedScale.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(minWidth: 140, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .menuStyle(.borderlessButton)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Range")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(model.octaveShiftLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        Slider(value: $model.octaveShift, in: -2...2, step: 1)
                    }
                }
                .padding(.top, 6)
            } label: {
                HStack {
                    Text("Key / Scale")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(model.selectedKey.displayName) · \(model.selectedScale.displayName)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var knobRow: some View {
        HStack(spacing: 20) {
            KnobView(title: "Delay", value: $model.delayMix)
            KnobView(title: "Reverb", value: $model.reverbMix)
        }
        .frame(maxWidth: .infinity)
    }

    private var instrumentRow: some View {
        HStack {
            Menu {
                ForEach(SoundProfileType.allCases) { sound in
                    Button(sound.displayName) {
                        model.selectedSound = sound
                    }
                }
            } label: {
                HStack {
                    Text(model.selectedSound.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private extension AppModel {
    var octaveShiftLabel: String {
        let value = Int(octaveShift.rounded())
        if value == 0 { return "Mid" }
        return value > 0 ? "+\(value)" : "\(value)"
    }
}
