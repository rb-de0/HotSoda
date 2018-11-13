import Vapor

public final class HotSodaProvider: Provider {

    public init() {}

    public func register(_ services: inout Services) throws {
        services.register { _ in
            return HotSodaCache()
        }
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}
