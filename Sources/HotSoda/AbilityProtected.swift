import Vapor

public protocol AbilityProtected {

    static func canCreate(on request: Request) throws -> Future<Void>

    func canRead(on request: Request) throws -> Future<Self>
    func canUpdate(on request: Request) throws -> Future<Self>
    func canDelete(on request: Request) throws -> Future<Self>
}

public extension Future where T: AbilityProtected {

    func canRead(on request: Request) -> Future<T> {
        return flatMap { try $0.canRead(on: request) }
    }

    func canUpdate(on request: Request) -> Future<T> {
        return flatMap { try $0.canUpdate(on: request) }
    }

    func canDelete(on request: Request) -> Future<T> {
        return flatMap { try $0.canDelete(on: request) }
    }
}

public extension Future {

    func canCreate<T: AbilityProtected>(_ authorizableType: T.Type, on request: Request) -> Future<Void> {
        return request.future().flatMap { try T.canCreate(on: request) }
    }
}
