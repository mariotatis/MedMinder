import Foundation
import Combine

class MedicationDiscoveryService {
    static let shared = MedicationDiscoveryService()
    
    private let baseURL = "https://api.fda.gov/drug/ndc.json"
    
    func searchMedications(query: String) -> AnyPublisher<[FDAMedication], Error> {
        guard query.count >= 3 else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchTerm = "\(cleanQuery)*"
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "30"),
            URLQueryItem(name: "search", value: searchTerm)
        ]
        
        guard let url = components?.url else {
            print("❌ Invalid URL for query: \(query)")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        print("🔍 Searching FDA API: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .timeout(.seconds(10), scheduler: DispatchQueue.main)
            .map { $0.data }
            .decode(type: FDAMedicationResponse.self, decoder: JSONDecoder())
            .map { response in
                var uniqueResults: [FDAMedication] = []
                var seenResults = Set<String>()
                
                for med in response.results {
                    let generic = med.generic_name?.capitalizeFirstLetterOnly() ?? ""
                    let brand = med.brand_name?.capitalizeFirstLetterOnly() ?? ""
                    
                    // Skip if both are empty
                    if generic.isEmpty && brand.isEmpty { continue }
                    
                    let uniqueKey = "\(generic)|\(brand)"
                    
                    if !seenResults.contains(uniqueKey) {
                        seenResults.insert(uniqueKey)
                        uniqueResults.append(FDAMedication(generic_name: generic, brand_name: brand))
                    }
                }
                
                print("✅ Found \(uniqueResults.count) unique results for: \(query)")
                return uniqueResults
            }
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("⚠️ FDA API handled error: \(error.localizedDescription)")
                }
            })
            .replaceError(with: []) // Silently return empty results on error
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
