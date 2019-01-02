import Fluent
import Vapor

final class AbilityProtectedMiddleware<T: AbilityProtected & Model & Parameter>: Middleware where T.ResolvedParameter == Future<T> {

    private let types: [AbilityType]

    init(for types: [AbilityType]) {
        self.types = types
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {

        let blockedAbilityTypes = types.contains(.all) ? AbilityType.allCases.filter { $0 != .all } : types
        let shouldVerifyCreateAbility = blockedAbilityTypes.contains(.create)
        let abilityTypesForModel = blockedAbilityTypes.filter { $0 != .create }
        let eventLoop = request.eventLoop

        func verifyRequestAbility(model: T) -> Future<T> {

            let abilityCheckTasks = abilityTypesForModel.map { type -> Future<Void> in
                return request.future().flatMap {
                    switch type {
                    case .read:
                        return try model.canRead(on: request).transform(to: ())
                    case .update:
                        return try model.canUpdate(on: request).transform(to: ())
                    case .delete:
                        return try model.canDelete(on: request).transform(to: ())
                    default:
                        return request.future(())
                    }
                }
            }

            return Future<Void>.andAll(abilityCheckTasks, eventLoop: eventLoop).transform(to: model)
        }

        func verify() throws -> Future<Void> {

            var verifyTasks = [Future<Void>]()

            if shouldVerifyCreateAbility {
                let verifyCreate = request.future()
                    .flatMap { try T.canCreate(on: request) }
                verifyTasks.append(verifyCreate)
            } else {
                let verifyModelsControl = try request.parameters.next(T.self)
                    .flatMap { (model: T) -> Future<T> in
                        verifyRequestAbility(model: model)
                    }
                    .flatMap { (model: T) -> Future<T> in
                        return request.future(try request.cacheControlAllowed(model: model))
                    }
                    .transform(to: ())
                verifyTasks.append(verifyModelsControl)
            }

            return Future<Void>.andAll(verifyTasks, eventLoop: eventLoop)
        }

        return try verify()
            .catchFlatMap {
                request.future(error: HotSodaError.make(from: $0))
            }.flatMap {
                try next.respond(to: request)
            }
    }
}

public extension Router {

    func protected<T>(_ subject: T.Type, for types: [AbilityType]) -> Router where T: AbilityProtected, T: Model, T: Parameter, T.ResolvedParameter == Future<T> {
        return grouped(AbilityProtectedMiddleware<T>(for: types))
    }
}

private extension Request {

    func cacheControlAllowed<T>(model: T) throws -> T where T: AbilityProtected {
        let cache = try privateContainer.make(HotSodaCache.self)
        cache.set(model)
        return model
    }
}

private extension HotSodaError {
    
    static func make(from error: Error) -> HotSodaError {
        return HotSodaError(status: .forbidden, identifier: error.localizedDescription, reason: error.localizedDescription)
    }
}
