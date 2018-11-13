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
                switch type {
                case .read:
                    return model.canRead(on: request).transform(to: ())
                case .update:
                    return model.canUpdate(on: request).transform(to: ())
                case .delete:
                    return model.canDelete(on: request).transform(to: ())
                default:
                    return request.future(())
                }
            }

            return Future<Void>.andAll(abilityCheckTasks, eventLoop: eventLoop).transform(to: model)
        }

        func verify() throws -> Future<Void> {

            var verifyTasks = [Future<Void>]()

            if shouldVerifyCreateAbility {
                verifyTasks.append(T.canCreate(on: request))
            }

            let verifyModelsControl = try request.parameters.next(T.self)
                .flatMap { (model: T) -> Future<T> in
                    verifyRequestAbility(model: model)
                }
                .flatMap { (model: T) -> Future<T> in
                    return request.future(try request.cacheControlAllowed(model: model))
                }
                .transform(to: ())

            verifyTasks.append(verifyModelsControl)

            return Future<Void>.andAll(verifyTasks, eventLoop: eventLoop)
        }

        return try verify().flatMap {
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
