import Foundation
import Combine

class FileStorageService {
    static let shared = FileStorageService()
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func save<T: Encodable>(_ items: [T], to fileName: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else { return }
            let url = self.getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                let data = try self.encoder.encode(items)
                try data.write(to: url)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func load<T: Decodable>(from fileName: String) -> AnyPublisher<[T], Error> {
        return Future<[T], Error> { [weak self] promise in
            guard let self = self else { return }
            let url = self.getDocumentsDirectory().appendingPathComponent(fileName)
            
            guard self.fileManager.fileExists(atPath: url.path) else {
                promise(.success([])) // Return empty array if file doesn't exist
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let items = try self.decoder.decode([T].self, from: data)
                promise(.success(items))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
