//
//  DraftSessionView.swift
//  FocusCue
//

import SwiftUI

struct DraftSessionView: View {
    @State private var draftService = ScriptDraftService()
    @State private var editableTranscript: String = ""
    @State private var phase: Phase = .recording

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onAccept: (String) -> Void
    var onClose: () -> Void
    var onBlockedFeature: (FeatureGate) -> Void

    enum Phase {
        case recording
        case review
        case refined
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(spacing: 0) {
            HStack {
                Text(headerTitle)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.heading)
                Spacer()
                if phase == .recording {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.color(.stateError))
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .fcTypography(.caption)
                            .foregroundStyle(theme.color(.stateError))
                    }
                }
            }
            .padding(.horizontal, FCSpacingToken.s16.rawValue)
            .padding(.top, FCSpacingToken.s16.rawValue)
            .padding(.bottom, FCSpacingToken.s12.rawValue)

            Divider()

            switch phase {
            case .recording:
                recordingView(theme: theme)
            case .review:
                reviewView(theme: theme)
            case .refined:
                refinedView(theme: theme)
            }

            Divider()

            actionBar(theme: theme)
                .padding(FCSpacingToken.s12.rawValue)
        }
        .frame(width: 480)
        .frame(minHeight: 400, maxHeight: 600)
        .background(theme.material(.card))
        .onAppear {
            draftService.startRecording()
        }
        .onDisappear {
            if draftService.isRecording {
                draftService.stopRecording()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { draftService.error != nil },
            set: { if !$0 { draftService.error = nil } }
        )) {
            Button("OK") { draftService.error = nil }
        } message: {
            Text(draftService.error ?? "")
        }
    }

    private var headerTitle: String {
        switch phase {
        case .recording: return "Free Run"
        case .review:    return "Review Transcript"
        case .refined:   return "Refined Script"
        }
    }

    private var reviewSubtitle: String {
        if DistributionFeatures.aiDraftRefinementVisible {
            return "Edit your transcript, then use it directly or refine it into a cleaner script."
        }
        return "Edit your transcript, then use it directly as a script."
    }

    @ViewBuilder
    private func recordingView(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s12.rawValue) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(draftService.rawTranscript.isEmpty ? "Start speaking\u{2026}" : draftService.rawTranscript)
                        .fcTypography(.bodyM)
                        .foregroundStyle(draftService.rawTranscript.isEmpty ? theme.color(.textTertiary) : theme.color(.textPrimary))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(FCSpacingToken.s12.rawValue)
                        .id("transcript")
                }
                .onChange(of: draftService.rawTranscript) { _, _ in
                    withAnimation {
                        proxy.scrollTo("transcript", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 2) {
                ForEach(Array(draftService.audioLevels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.color(.stateError).opacity(0.7))
                        .frame(width: 3, height: max(2, level * 24))
                }
            }
            .frame(height: 28)
            .animation(.easeOut(duration: 0.1), value: draftService.audioLevels)
            .padding(.horizontal, FCSpacingToken.s16.rawValue)
            .padding(.bottom, FCSpacingToken.s8.rawValue)
        }
    }

    @ViewBuilder
    private func reviewView(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s8.rawValue) {
            Text(reviewSubtitle)
                .fcTypography(.caption)
                .foregroundStyle(theme.color(.textSecondary))
                .padding(.horizontal, FCSpacingToken.s16.rawValue)
                .padding(.top, FCSpacingToken.s8.rawValue)

            TextEditor(text: $editableTranscript)
                .fcTypography(.bodyM)
                .scrollContentBackground(.hidden)
                .padding(FCSpacingToken.s8.rawValue)
                .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func refinedView(theme: FCTheme) -> some View {
        Group {
            if draftService.isRefining {
                VStack(spacing: FCSpacingToken.s12.rawValue) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Refining your script\u{2026}")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textSecondary))
                    Spacer()
                }
            } else {
                ScrollView {
                    Text(draftService.refinedText)
                        .fcTypography(.bodyM)
                        .foregroundStyle(theme.color(.textPrimary))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(FCSpacingToken.s12.rawValue)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func actionBar(theme: FCTheme) -> some View {
        HStack {
            Button("Cancel") {
                draftService.stopRecording()
                onClose()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(theme.color(.textTertiary))

            Spacer()

            switch phase {
            case .recording:
                Button {
                    draftService.stopRecording()
                    editableTranscript = draftService.rawTranscript
                    withAnimation(theme.animation(.base)) {
                        phase = .review
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                        Text("Stop")
                            .fcTypography(.label)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.color(.stateError))
                .controlSize(.regular)
                .disabled(draftService.rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            case .review:
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Button {
                        onAccept(editableTranscript)
                        onClose()
                    } label: {
                        Text("Use as Script")
                            .fcTypography(.label)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

Button {
                        draftService.rawTranscript = editableTranscript
                        withAnimation(theme.animation(.base)) {
                            phase = .refined
                        }
                        draftService.refine()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("Refine with AI")
                                .fcTypography(.label)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

            case .refined:
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Button {
                        withAnimation(theme.animation(.base)) {
                            phase = .review
                        }
                    } label: {
                        Text("Back")
                            .fcTypography(.label)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        onAccept(draftService.refinedText)
                        onClose()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Use This")
                                .fcTypography(.label)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(draftService.isRefining || draftService.refinedText.isEmpty)
                }
            }
        }
    }
}
