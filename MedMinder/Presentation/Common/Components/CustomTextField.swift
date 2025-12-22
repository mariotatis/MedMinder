import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.surface)
                .cornerRadius(8)
                .foregroundColor(.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct CustomFocusedTextField<Value: Hashable>: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var focusState: FocusState<Value?>.Binding
    var focusValue: Value
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.surface)
                .cornerRadius(8)
                .foregroundColor(.textPrimary)
                .focused(focusState, equals: focusValue)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
