import Vapor

public protocol AbilityProtected {

    static func canCreate(on request: Request) -> Future<Void>

    func canRead(on request: Request) -> Future<Self>
    func canUpdate(on request: Request) -> Future<Self>
    func canDelete(on request: Request) -> Future<Self>
}

public extension Future where T: AbilityProtected {

    func canRead(on request: Request) -> Future<T> {
        return flatMap { $0.canRead(on: request) }
    }

    func canUpdate(on request: Request) -> Future<T> {
        return flatMap { $0.canUpdate(on: request) }
    }

    func canDelete(on request: Request) -> Future<T> {
        return flatMap { $0.canDelete(on: request) }
    }
}

public extension Future {

    func canCreate<T: AbilityProtected>(_ authorizableType: T.Type, on request: Request) -> Future<Void> {
        return T.canCreate(on: request)
    }
}
