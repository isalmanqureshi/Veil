//
//  Redesign+ComposerBar.swift
//  Veil
//
//  Chat composer: attach, emoji, growing text field, timer button, send.
//  Callback-based so it stays free of networking and view-model specifics.
//

import SwiftUI

extension Redesign {

    struct ComposerBar: View {
        @Binding var text: String
        let timer: MessageTimer

        var onAttach: () -> Void = {}
        var onEmoji: () -> Void = {}
        var onTimerTap: () -> Void = {}
        var onSend: () -> Void = {}

        @FocusState private var isFocused: Bool

        private var canSend: Bool {
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var body: some View {
            HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                iconButton("paperclip", label: "Add attachment", action: onAttach)

                HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                    TextField("Message", text: $text, axis: .vertical)
                        .font(Theme.Fonts.body)
                        .lineLimit(1...4)
                        .focused($isFocused)

                    Button(action: onEmoji) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .accessibilityLabel("Insert emoji")
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, 10)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control + 6, style: .continuous))

                // Disappearing-timer control — always visible, part of composing.
                Button(action: onTimerTap) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: timer.symbolName)
                        Text(timer.rawValue)
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.horizontal, Theme.Spacing.s)
                    .frame(minHeight: 44)
                    .background(Theme.Colors.accentSoft)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Disappearing timer: \(timer.rawValue)")

                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.onAccent)
                        .frame(width: 44, height: 44)
                        .background(canSend ? Theme.Colors.accent : Theme.Colors.separator)
                        .clipShape(Circle())
                }
                .disabled(!canSend)
                .animation(.easeOut(duration: 0.15), value: canSend)
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(.bar)
        }

        private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(label)
        }
    }
}

#Preview("Composer") {
    struct Host: View {
        @State private var text = ""
        var body: some View {
            VStack {
                Spacer()
                Redesign.ComposerBar(text: $text, timer: .hour1)
            }
            .background(Theme.Colors.background)
        }
    }
    return Host()
}
