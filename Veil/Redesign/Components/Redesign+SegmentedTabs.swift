//
//  Redesign+SegmentedTabs.swift
//  Veil
//
//  Two-segment pill control for the inbox (Chats / Requests) with an
//  animated selection capsule and an optional count badge.
//

import SwiftUI

extension Redesign {

    struct SegmentedTabs: View {
        struct Segment: Identifiable, Equatable {
            let id: String
            let title: String
            var badgeCount: Int = 0
        }

        let segments: [Segment]
        @Binding var selectedID: String

        @Namespace private var selection

        var body: some View {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(segments) { segment in
                    segmentButton(segment)
                }
            }
            .padding(Theme.Spacing.xs)
            .background(Theme.Colors.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Theme.Colors.separator, lineWidth: 1))
        }

        private func segmentButton(_ segment: Segment) -> some View {
            let isSelected = segment.id == selectedID

            return Button {
                withAnimation(.spring(duration: 0.3)) {
                    selectedID = segment.id
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(segment.title)
                        .font(Theme.Fonts.headline)

                    if segment.badgeCount > 0 {
                        Text("\(segment.badgeCount)")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.onAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Theme.Colors.onAccent : Theme.Colors.accent)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(isSelected ? Theme.Colors.onAccent : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(minHeight: 40)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Theme.Colors.accent)
                            .matchedGeometryEffect(id: "segment", in: selection)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(segment.title)\(segment.badgeCount > 0 ? ", \(segment.badgeCount) new" : "")")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}

#Preview("Segmented tabs") {
    struct Host: View {
        @State private var selected = "chats"
        var body: some View {
            Redesign.SegmentedTabs(
                segments: [
                    .init(id: "chats", title: "Chats"),
                    .init(id: "requests", title: "Requests", badgeCount: 3)
                ],
                selectedID: $selected
            )
            .padding(Theme.Spacing.m)
            .background(Theme.Colors.background)
        }
    }
    return Host()
}
