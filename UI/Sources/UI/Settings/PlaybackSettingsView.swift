import SwiftUI
import Core

/// Playback settings section
public struct PlaybackSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("Deinterlacing") {
                Picker("Mode", selection: $viewModel.deinterlacingMode) {
                    ForEach(DeinterlacingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Text(deinterlacingDescription(viewModel.deinterlacingMode))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Video") {
                Toggle("Hardware Decode", isOn: $viewModel.hardwareDecodeEnabled)
                    .help("Use GPU acceleration for video decoding")

                HStack {
                    Text("Buffer Size (ms)")
                    TextField("", value: $viewModel.bufferSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func deinterlacingDescription(_ mode: DeinterlacingMode) -> String {
        switch mode {
        case .auto: return "Automatically select best deinterlacing for the stream"
        case .off: return "No deinterlacing (may show combing on interlaced content)"
        case .bob: return "Bob deinterlacing - doubles framerate, good for sports"
        case .yadif: return "Yadif - high quality, standard deinterlacing"
        case .yadif2x: return "Yadif 2x - doubles framerate with Yadif"
        case .phosphor: return "Phosphor - smooth motion, simulates CRT"
        case .blend: return "Linear blend - simple, may lose detail"
        }
    }
}