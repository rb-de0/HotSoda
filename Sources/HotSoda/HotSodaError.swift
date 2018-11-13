import Vapor

public struct HotSodaError: Error, AbortError {

    public let status: HTTPStatus
    public let identifier: String
    public let reason: String

    public init(status: HTTPStatus, identifier: String, reason: String) {
        self.status = status
        self.identifier = identifier
        self.reason = reason
    }

    public init(abilityType: AbilityType) {
        let identifier = "No \(abilityType) ability"
        self.init(status: .forbidden, identifier: identifier, reason: identifier)
    }
}
