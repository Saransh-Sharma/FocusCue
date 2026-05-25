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
            headerView(theme: theme)

            Rectangle()
                .fill(theme.color(.controlBorder))
                .frame(height: 1)

            switch phase {
            case .recording:
                recordingView(theme: theme)
            case .review:
                reviewView(theme: theme)
            case .refined:
                refinedView(theme: theme)
            }

            Rectangle()
                .fill(theme.color(.controlBorder))
                .frame(height: 1)

            actionBar(theme: theme)
                .padding(FCSpacingToken.s12.rawValue)
        }
        .frame(width: 480)
        .frame(minHeight: 400, maxHeight: 600)
        .background(theme.color(.surfaceSlate))
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius20.rawValue, style: .continuous)
                .stroke(theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue)
        )
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

    @ViewBuilder
    private func headerView(theme: FCTheme) -> some View {
        HStack {
            Text(headerTitle)
                .foregroundStyle(theme.color(.textPrimary))
                .fcTypography(.heading)
            Spacer()
            if phase == .recording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.color(.recordingPink))
                        .frame(width: 8, height: 8)
                    Text("RECORDING")
                        .fcTypography(.monoTimestamp)
                        .foregroundStyle(theme.color(.recordingPink))
                }
            }
        }
        .padding(.horizontal, FCSpacingToken.s16.rawValue)
        .padding(.top, FCSpacingToken.s16.rawValue)
        .padding(.bottom, FCSpacingToken.s12.rawValue)
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
                    withAnimation(theme.animation(.base)) {
                        proxy.scrollTo("transcript", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 2) {
                ForEach(Array(draftService.audioLevels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.color(.recordingPink).opacity(0.8))
                        .frame(width: 3, height: max(2, level * 24))
                }
            }
            .frame(height: 28)
            .animation(theme.animation(.fast), value: draftService.audioLevels)
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
                    VStack(spacing: FCSpacingToken.s6.rawValue) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: FCShapeToken.radius2.rawValue, style: .continuous)
                                .fill(theme.color(.resyncViolet).opacity(0.24 + Double(index) * 0.18))
                                .frame(width: 180 - CGFloat(index * 24), height: 6)
                        }
                    }
                    Text("REFINING SCRIPT")
                        .fcTypography(.labelCaps)
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
            .buttonStyle(.plain)
            .foregroundStyle(theme.color(.textTertiary))

            Spacer()

            switch phase {
            case .recording:
                let canStop = !draftService.rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                .buttonStyle(.plain)
                .foregroundStyle(canStop ? theme.onAccentForeground(for: .recordingPink) : theme.color(.textDisabled))
                .padding(.horizontal, FCSpacingToken.s16.rawValue)
                .padding(.vertical, FCSpacingToken.s8.rawValue)
                .background(Capsule(style: .continuous).fill(canStop ? theme.color(.recordingPink) : theme.color(.surfaceInset)))
                .overlay(Capsule(style: .continuous).stroke(canStop ? theme.color(.recordingPink) : theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue))
                .controlSize(.regular)
                .disabled(!canStop)

            case .review:
                let canRefine = !editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Button {
                        onAccept(editableTranscript)
                        onClose()
                    } label: {
                        Text("Use as Script")
                            .fcTypography(.label)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.color(.cueMint))
                    .padding(.horizontal, FCSpacingToken.s12.rawValue)
                    .padding(.vertical, FCSpacingToken.s8.rawValue)
                    .background(Capsule(style: .continuous).fill(theme.color(.canvasBlack)))
                    .overlay(Capsule(style: .continuous).stroke(theme.color(.cueMint), lineWidth: FCStrokeToken.thin.rawValue))
                    .controlSize(.regular)

                    Button {
                        draftService.rawTranscript = editableTranscript
                        withAnimation(theme.animation(.base)) {
                            phase = .refined
                        }
                        draftService.refine()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                            Text("Refine with AI")
                                .fcTypography(.label)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(canRefine ? theme.onAccentForeground(for: .resyncViolet) : theme.color(.textDisabled))
                    .padding(.horizontal, FCSpacingToken.s12.rawValue)
                    .padding(.vertical, FCSpacingToken.s8.rawValue)
                    .background(Capsule(style: .continuous).fill(canRefine ? theme.color(.resyncViolet) : theme.color(.surfaceInset)))
                    .overlay(Capsule(style: .continuous).stroke(canRefine ? theme.color(.resyncVioletText) : theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue))
                    .controlSize(.regular)
                    .disabled(!canRefine)
                }

            case .refined:
                let canUseRefined = !draftService.isRefining && !draftService.refinedText.isEmpty
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Button {
                        withAnimation(theme.animation(.base)) {
                            phase = .review
                        }
                    } label: {
                        Text("Back")
                            .fcTypography(.label)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.color(.textMuted))
                    .padding(.horizontal, FCSpacingToken.s12.rawValue)
                    .padding(.vertical, FCSpacingToken.s8.rawValue)
                    .background(Capsule(style: .continuous).fill(theme.color(.canvasBlack)))
                    .overlay(Capsule(style: .continuous).stroke(theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue))
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
                    .buttonStyle(.plain)
                    .foregroundStyle(canUseRefined ? theme.onAccentForeground(for: .cueMint) : theme.color(.textDisabled))
                    .padding(.horizontal, FCSpacingToken.s12.rawValue)
                    .padding(.vertical, FCSpacingToken.s8.rawValue)
                    .background(Capsule(style: .continuous).fill(canUseRefined ? theme.color(.cueMint) : theme.color(.surfaceInset)))
                    .overlay(Capsule(style: .continuous).stroke(canUseRefined ? theme.color(.cueMintBorder) : theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue))
                    .controlSize(.regular)
                    .disabled(!canUseRefined)
                }
            }
        }
    }
}
