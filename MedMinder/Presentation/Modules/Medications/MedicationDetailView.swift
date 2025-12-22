import SwiftUI

/// This view is maintained to satisfy existing Xcode project file references.
/// The implementation has been unified into UnifiedMedicationDetailView.
struct MedicationDetailView: View {
    let viewModel: TreatmentMedicationDetailViewModel
    
    var body: some View {
        UnifiedMedicationDetailView(viewModel: viewModel)
    }
}
