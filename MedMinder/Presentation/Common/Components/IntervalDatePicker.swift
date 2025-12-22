import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIDatePicker that supports custom minute intervals.
struct IntervalDatePicker: UIViewRepresentable {
    @Binding var selection: Date
    let minuteInterval: Int
    let displayedComponents: DatePickerComponents
    
    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.minuteInterval = minuteInterval
        
        if displayedComponents == .hourAndMinute {
            picker.datePickerMode = .time
        } else if displayedComponents == .date {
            picker.datePickerMode = .date
        } else {
            picker.datePickerMode = .dateAndTime
        }
        
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }
    
    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = selection
        uiView.minuteInterval = minuteInterval
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: IntervalDatePicker
        
        init(_ parent: IntervalDatePicker) {
            self.parent = parent
        }
        
        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.selection = sender.date
        }
    }
}
