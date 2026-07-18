//
//  Redesign+TimerSelectorSheet.swift
//  Veil
//
//  Disappearing-timer picker. Binds to the real MessageTimer enum
//  (including the Pro-gated .custom case).
//

import SwiftUI

extension Redesign {

    struct TimerSelectorSheet: View {
        @Binding var selected: MessageTimer
        var isProUnlocked: Bool = false
        var onUpgradeTap: () -> Void = {}

        @Environment(\.dismiss) private var dismiss

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("Disappearing timer")
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("New messages in this chat quietly delete themselves for everyone after this window.")
                    .font(Theme.Fonts.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)

                VStack(spacing: Theme.Spacing.s) {
                    ForEach(MessageTimer.allCases) { timer in
                        timerRow(timer)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.l)
            .background(Theme.Colors.background)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }

        private func timerRow(_ timer: MessageTimer) -> some View {
            let isLocked = timer == .custom && !isProUnlocked
            let isSelected = selected == timer

            return Button {
                if isLocked {
                    onUpgradeTap()
                    return
                }
                selected = timer
                dismiss()
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    Image(systemName: timer.symbolName)
                        .font(.system(size: 17))
                        .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textSecondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(timer.rawValue)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(timer.explanation)
                            .font(Theme.Fonts.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    if isLocked {
                        Text("Pro").chip(tint: Theme.Colors.accent)
                    } else if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .padding(Theme.Spacing.m)
                .background(isSelected ? Theme.Colors.accentSoft : Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(timer.rawValue)\(isLocked ? ", requires Pro" : "")\(isSelected ? ", selected" : "")")
        }
    }
}

#Preview("Timer selector") {
    struct Host: View {
        @State private var timer: MessageTimer = .hour1
        var body: some View {
            Redesign.TimerSelectorSheet(selected: $timer)
        }
    }
    return Host()
}
