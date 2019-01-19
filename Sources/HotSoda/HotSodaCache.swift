import Vapor

final class HotSodaCache: Service {

    private var storage: [ObjectIdentifier: Any]

    init() {
        self.storage = [:]
    }

    func get<T>(_ type: T.Type) -> T? where T: AbilityProtected {
        return storage[ObjectIdentifier(T.self)] as? T
    }

    func set<T>(_ instance: T) where T: AbilityProtected {
        storage[ObjectIdentifier(T.self)] = instance
    }
}

public extension Request {

    func controllable<T>(_ type: T.Type) throws -> T? where T: AbilityProtected {
        let cache = try privateContainer.make(HotSodaCache.self)
        return cache.get(T.self)
    }

    func requireControllable<T>(_ type: T.Type) throws -> T where T: AbilityProtected {
        guard let allowed = try controllable(T.self) else {
            throw HotSodaError(status: .forbidden, identifier: "model is protected", reason: "model is protected")
        }
        return allowed
    }
}
