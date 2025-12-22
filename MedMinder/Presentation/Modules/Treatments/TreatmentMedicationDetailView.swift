import SwiftUI

/// This view is a wrapper around the UnifiedMedicationDetailView
/// It is maintained to satisfy existing Xcode project file references.
struct TreatmentMedicationDetailView: View {
    @StateObject var viewModel: TreatmentMedicationDetailViewModel
    
    var body: some View {
        UnifiedMedicationDetailView(viewModel: viewModel)
    }
}
