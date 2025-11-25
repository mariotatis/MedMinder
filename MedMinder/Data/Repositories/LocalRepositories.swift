import Foundation
import Combine

class LocalProfileRepository: ProfileRepository {
    private let fileName = "profiles.json"
    private let storage = FileStorageService.shared
    private var cache: [Profile] = []
    
    func getProfiles() -> AnyPublisher<[Profile], Error> {
        return storage.load(from: fileName)
            .handleEvents(receiveOutput: { [weak self] profiles in
                self?.cache = profiles
            })
            .eraseToAnyPublisher()
    }
    
    func addProfile(_ profile: Profile) -> AnyPublisher<Void, Error> {
        cache.append(profile)
        return storage.save(cache, to: fileName)
    }
    
    func updateProfile(_ profile: Profile) -> AnyPublisher<Void, Error> {
        if let index = cache.firstIndex(where: { $0.id == profile.id }) {
            cache[index] = profile
            return storage.save(cache, to: fileName)
        }
        return Fail(error: NSError(domain: "ProfileNotFound", code: 404, userInfo: nil)).eraseToAnyPublisher()
    }
    
    func deleteProfile(id: UUID) -> AnyPublisher<Void, Error> {
        cache.removeAll { $0.id == id }
        return storage.save(cache, to: fileName)
    }
}

class LocalTreatmentRepository: TreatmentRepository {
    private let fileName = "treatments.json"
    private let storage = FileStorageService.shared
    private var cache: [Treatment] = []
    
    func getTreatments() -> AnyPublisher<[Treatment], Error> {
        return storage.load(from: fileName)
            .handleEvents(receiveOutput: { [weak self] treatments in
                self?.cache = treatments
            })
            .eraseToAnyPublisher()
    }
    
    func addTreatment(_ treatment: Treatment) -> AnyPublisher<Void, Error> {
        cache.append(treatment)
        return storage.save(cache, to: fileName)
    }
    
    func updateTreatment(_ treatment: Treatment) -> AnyPublisher<Void, Error> {
        if let index = cache.firstIndex(where: { $0.id == treatment.id }) {
            cache[index] = treatment
            return storage.save(cache, to: fileName)
        }
        return Fail(error: NSError(domain: "TreatmentNotFound", code: 404, userInfo: nil)).eraseToAnyPublisher()
    }
    
    func deleteTreatment(id: UUID) -> AnyPublisher<Void, Error> {
        cache.removeAll { $0.id == id }
        return storage.save(cache, to: fileName)
    }
}

class LocalMedicationRepository: MedicationRepository {
    private let medsFileName = "medications.json"
    private let logsFileName = "doselogs.json"
    private let storage = FileStorageService.shared
    private var medsCache: [Medication] = []
    private var logsCache: [DoseLog] = []
    
    func getMedications() -> AnyPublisher<[Medication], Error> {
        return storage.load(from: medsFileName)
            .handleEvents(receiveOutput: { [weak self] meds in
                self?.medsCache = meds
            })
            .eraseToAnyPublisher()
    }
    
    func addMedication(_ medication: Medication) -> AnyPublisher<Void, Error> {
        medsCache.append(medication)
        return storage.save(medsCache, to: medsFileName)
    }
    
    func updateMedication(_ medication: Medication) -> AnyPublisher<Void, Error> {
        if let index = medsCache.firstIndex(where: { $0.id == medication.id }) {
            medsCache[index] = medication
            return storage.save(medsCache, to: medsFileName)
        }
        return Fail(error: NSError(domain: "MedicationNotFound", code: 404, userInfo: nil)).eraseToAnyPublisher()
    }
    
    func deleteMedication(id: UUID) -> AnyPublisher<Void, Error> {
        medsCache.removeAll { $0.id == id }
        return storage.save(medsCache, to: medsFileName)
    }
    
    func getDoseLogs() -> AnyPublisher<[DoseLog], Error> {
        return storage.load(from: logsFileName)
            .handleEvents(receiveOutput: { [weak self] logs in
                self?.logsCache = logs
            })
            .eraseToAnyPublisher()
    }
    
    func logDose(_ log: DoseLog) -> AnyPublisher<Void, Error> {
        if let index = logsCache.firstIndex(where: { $0.id == log.id }) {
            logsCache[index] = log
        } else {
            logsCache.append(log)
        }
        return storage.save(logsCache, to: logsFileName)
    }
}
