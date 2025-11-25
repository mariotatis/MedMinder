import Foundation
import Combine

protocol ProfileRepository {
    func getProfiles() -> AnyPublisher<[Profile], Error>
    func addProfile(_ profile: Profile) -> AnyPublisher<Void, Error>
    func updateProfile(_ profile: Profile) -> AnyPublisher<Void, Error>
    func deleteProfile(id: UUID) -> AnyPublisher<Void, Error>
}

protocol TreatmentRepository {
    func getTreatments() -> AnyPublisher<[Treatment], Error>
    func addTreatment(_ treatment: Treatment) -> AnyPublisher<Void, Error>
    func updateTreatment(_ treatment: Treatment) -> AnyPublisher<Void, Error>
    func deleteTreatment(id: UUID) -> AnyPublisher<Void, Error>
}

protocol MedicationRepository {
    func getMedications() -> AnyPublisher<[Medication], Error>
    func addMedication(_ medication: Medication) -> AnyPublisher<Void, Error>
    func updateMedication(_ medication: Medication) -> AnyPublisher<Void, Error>
    func deleteMedication(id: UUID) -> AnyPublisher<Void, Error>
    func getDoseLogs() -> AnyPublisher<[DoseLog], Error>
    func logDose(_ log: DoseLog) -> AnyPublisher<Void, Error>
}
