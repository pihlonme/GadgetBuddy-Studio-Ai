import GadgetBuddyCore
import SwiftUI

public struct SongCommandScreen: View {
    @ObservedObject private var model: SongCommandScreenModel

    public init(model: SongCommandScreenModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                inputPanel
                statusPanel
                if let report = model.report {
                    commandPanel(report.interpretedCommand)
                    tracePanel(report)
                }
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Song Command Studio")
                .font(.largeTitle.bold())
            Text("Prompt → provider → SongCommand → Challenger → live report")
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var inputPanel: some View {
        GroupBox("Music instruction") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $model.prompt)
                    .frame(minHeight: 120)
                    .font(.body)
                    .accessibilityLabel("Music instruction")

                HStack(alignment: .center, spacing: 12) {
                    Picker("Provider", selection: $model.providerMode) {
                        ForEach(model.availableModes) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360)

                    Spacer(minLength: 0)

                    Button {
                        Task { await model.interpret() }
                    } label: {
                        if model.isRunning {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Interpret", systemImage: "waveform.and.magnifyingglass")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRunning)
                    .keyboardShortcut(.return, modifiers: [.command])
                }

                if !model.aiAvailable {
                    Text("AI mode becomes available when the host injects an AI provider. Deterministic mode works offline.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.callout)
                        .accessibilityLabel("Error: \(errorMessage)")
                }
            }
            .padding(.top, 4)
        }
    }

    private var statusPanel: some View {
        GroupBox("Pipeline status") {
            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.statusText).font(.headline)
                    Text(statusDetail).font(.caption).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    private func commandPanel(_ command: SongCommand) -> some View {
        GroupBox("Structured SongCommand") {
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    fieldCard("Intent", value: command.intent)
                    fieldCard("Genre", value: command.genre)
                    fieldCard("BPM", value: command.bpm.map(String.init))
                    fieldCard("Key", value: command.key)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Confidence").font(.headline)
                        Spacer()
                        Text("\(Int((command.confidence * 100).rounded()))%")
                            .monospacedDigit()
                    }
                    ProgressView(value: command.confidence, total: 1)
                }

                tokenSection(title: "Mood", values: command.mood, emptyText: "No explicit mood")
                tokenSection(title: "Missing fields", values: command.missingFields, emptyText: "No core fields missing")

                if let structure = command.structure {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Structure").font(.headline)
                        Text(structureSummary(structure))
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }

                tokenSection(title: "References", values: command.references, emptyText: "No explicit references")
            }
            .padding(.top, 4)
        }
    }

    private func tracePanel(_ report: SandboxReport) -> some View {
        GroupBox("Execution trace") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(report.trace.enumerated()), id: \.offset) { index, event in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit())
                            .frame(width: 24, height: 24)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.stage.capitalized).font(.callout.bold())
                            Text(event.message).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func fieldCard(_ title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value ?? "Missing")
                .font(.headline)
                .foregroundColor(value == nil ? .orange : .primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
    }

    private func tokenSection(title: String, values: [String], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if values.isEmpty {
                Text(emptyText).font(.callout).foregroundColor(.secondary)
            } else {
                FlowTokens(values: values)
            }
        }
    }

    private func structureSummary(_ structure: SongStructure) -> String {
        var parts: [String] = []
        if let intro = structure.intro { parts.append("intro: \(intro)") }
        if let breakPresent = structure.breakPresent { parts.append("break: \(breakPresent ? "yes" : "no")") }
        if let drop = structure.drop { parts.append("drop: \(drop)") }
        return parts.isEmpty ? "No explicit structure details" : parts.joined(separator: " • ")
    }

    private var statusIcon: String {
        guard let report = model.report else { return "circle.dashed" }
        if !report.passed { return "xmark.octagon.fill" }
        return report.interpretedCommand.missingFields.isEmpty ? "checkmark.seal.fill" : "questionmark.circle.fill"
    }

    private var statusColor: Color {
        guard let report = model.report else { return .secondary }
        if !report.passed { return .red }
        return report.interpretedCommand.missingFields.isEmpty ? .green : .orange
    }

    private var statusDetail: String {
        guard let report = model.report else { return "Enter a prompt and run the interpreter." }
        if !report.passed { return "Challenger detected \(report.challengerIssues.count) contract issue(s)." }
        let missing = report.interpretedCommand.missingFields
        return missing.isEmpty ? "The command can move to the next module." : "Contract is valid; complete: \(missing.joined(separator: ", "))."
    }
}

private struct FlowTokens: View {
    let values: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(999)
            }
        }
    }
}
