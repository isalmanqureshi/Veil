//
//  CheckboxView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//

import SwiftUI

struct CheckboxView: View {
    
    @Binding var isChecked: Bool
    let label: String
    
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(isChecked ? .primary : .secondary)
                
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CheckboxPreviewContainer()
}


private struct CheckboxPreviewContainer: View {

    @State private var checked = false

    var body: some View {
        CheckboxView(
            isChecked: $checked,
            label: "I understand that this key cannot be recovered if lost."
        )
        .padding()
    }
}
