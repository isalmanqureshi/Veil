//
//  MessageTimerSelectorView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

enum MessageTimer: String, CaseIterable, Identifiable {
    case seconds30 = "30 sec"
    case minutes5 = "5 min"
    case hour1 = "1 hr"
    case day1 = "1 day"
    case custom = "Custom"

    var id: String { rawValue }
}


struct MessageTimerSelectorView: View {

    @Binding var selectedTimer: MessageTimer
    @Binding var makeDefault: Bool

    var body: some View {
        VStack(spacing: 20) {

            Text("Message timer")
                .font(.system(size: 18, weight: .semibold))

            ForEach(MessageTimer.allCases) { timer in
                Button {
                    selectedTimer = timer
                } label: {
                    HStack {
                        Text(timer.rawValue)
                        Spacer()
                        if selectedTimer == timer {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            CheckboxView(
                isChecked: $makeDefault,
                label: "Make default for this chat"
            )

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}


#Preview {
    MessageTimerSelectorPreviewContainer()
}

private struct MessageTimerSelectorPreviewContainer: View {

    @State private var timer: MessageTimer = .day1
    @State private var makeDefault = false

    var body: some View {
        MessageTimerSelectorView(
            selectedTimer: $timer,
            makeDefault: $makeDefault
        )
    }
}
