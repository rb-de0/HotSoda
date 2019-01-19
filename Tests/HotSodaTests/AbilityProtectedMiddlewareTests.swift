@testable import HotSoda
import FluentSQLite
import Vapor
import XCTest

final class AbilityProtectedMiddlewareTests: XCTestCase {

    private var app: Application!
    private var responder: Responder!
    private var router: Router!
    private var conn: SQLiteConnection!

    func testCanProtectAbilities() throws {

        try makeApp()
        _ = try AllProtectedModel().save(on: conn).wait()

        router.protected(AllProtectedModel.self, for: [.create]).post("/") { _ -> HTTPStatus in
            return .ok
        }

        router.protected(AllProtectedModel.self, for: [.read]).get("/", AllProtectedModel.parameter) { _ -> HTTPStatus in
            return .ok
        }

        router.protected(AllProtectedModel.self, for: [.update]).put("/", AllProtectedModel.parameter) { _ -> HTTPStatus in
            return .ok
        }

        router.protected(AllProtectedModel.self, for: [.delete]).delete("/", AllProtectedModel.parameter) { _ -> HTTPStatus in
            return .ok
        }

        var response = try waitResponse(.GET, url: "/1")
        XCTAssertEqual(response.http.status, .forbidden)

        response = try waitResponse(.POST, url: "/")
        XCTAssertEqual(response.http.status, .forbidden)

        response = try waitResponse(.PUT, url: "/1")
        XCTAssertEqual(response.http.status, .forbidden)

        response = try waitResponse(.DELETE, url: "/1")
        XCTAssertEqual(response.http.status, .forbidden)
    }

    func canPassAbilitiesCheck() throws {

        try makeApp()
        _ = try NoProtectedModel().save(on: conn).wait()

        router.protected(NoProtectedModel.self, for: [.create]).post("/") { request -> NoProtectedModel in
            return try request.requireControllable(NoProtectedModel.self)
        }

        router.protected(NoProtectedModel.self, for: [.read]).get("/", NoProtectedModel.parameter) { request -> NoProtectedModel in
            return try request.requireControllable(NoProtectedModel.self)
        }

        router.protected(NoProtectedModel.self, for: [.update]).put("/", NoProtectedModel.parameter) { request -> NoProtectedModel in
            return try request.requireControllable(NoProtectedModel.self)
        }

        router.protected(NoProtectedModel.self, for: [.delete]).delete("/", NoProtectedModel.parameter) { request -> NoProtectedModel in
            return try request.requireControllable(NoProtectedModel.self)
        }

        var response = try waitResponse(.GET, url: "/1")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(NoProtectedModel.self))

        response = try waitResponse(.POST, url: "/")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(NoProtectedModel.self))

        response = try waitResponse(.PUT, url: "/1")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(NoProtectedModel.self))

        response = try waitResponse(.DELETE, url: "/1")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(NoProtectedModel.self))
    }

    func testCanProtectCreate() throws {

        try makeApp()
        _ = try CreateProtectedModel().save(on: conn).wait()

        router.protected(CreateProtectedModel.self, for: [.create]).post("/") { request -> CreateProtectedModel in
            return try request.requireControllable(CreateProtectedModel.self)
        }

        router.protected(CreateProtectedModel.self, for: [.read]).get("/", CreateProtectedModel.parameter) { request -> CreateProtectedModel in
            return try request.requireControllable(CreateProtectedModel.self)
        }

        router.protected(CreateProtectedModel.self, for: [.update]).put("/", CreateProtectedModel.parameter) { request -> CreateProtectedModel in
            return try request.requireControllable(CreateProtectedModel.self)
        }

        router.protected(CreateProtectedModel.self, for: [.delete]).delete("/", CreateProtectedModel.parameter) { request -> CreateProtectedModel in
            return try request.requireControllable(CreateProtectedModel.self)
        }

        var response = try waitResponse(.GET, url: "/1")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(CreateProtectedModel.self))

        response = try waitResponse(.POST, url: "/")
        XCTAssertEqual(response.http.status, .forbidden)
        XCTAssertThrowsError(try response.content.syncDecode(CreateProtectedModel.self))

        response = try waitResponse(.PUT, url: "/1")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(CreateProtectedModel.self))

        response = try waitResponse(.DELETE, url: "/1")
        XCTAssertEqual(response.http.status, .ok)
        XCTAssertNoThrow(try response.content.syncDecode(CreateProtectedModel.self))
    }

    // MARK: - Helper

    private func makeApp() throws {
        let config = Config.default()
        let environment = try Environment.detect()
        var services = Services.default()

        try services.register(HotSodaProvider())
        try services.register(FluentSQLiteProvider())

        let sqlite = try SQLiteDatabase(storage: .memory)
        var databases = DatabasesConfig()
        databases.add(database: sqlite, as: .sqlite)
        services.register(databases)

        var migrations = MigrationConfig()
        migrations.add(model: AllProtectedModel.self, database: .sqlite)
        migrations.add(model: NoProtectedModel.self, database: .sqlite)
        migrations.add(model: CreateProtectedModel.self, database: .sqlite)
        services.register(migrations)

        self.app = try Application(config: config, environment: environment, services: services)
        self.router = try app.make(Router.self)
        self.responder = try app.make(Responder.self)
        self.conn = try app.newConnection(to: .sqlite).wait()
    }

    private func waitResponse(_ method: HTTPMethod, url: String) throws -> Response {
        let httpRequest = HTTPRequest(method: method, url: url)
        let request = Request(http: httpRequest, using: app)
        return try responder.respond(to: request).wait()
    }
}

private final class AllProtectedModel: TestModel {

    var id: Int?
    var content: String = ""

    static func canCreate(on request: Request) throws -> Future<Void> {
        return request.future(error: HotSodaError(abilityType: .create))
    }

    func canRead(on request: Request) throws -> Future<AllProtectedModel> {
        return request.future(error: HotSodaError(abilityType: .read))
    }

    func canUpdate(on request: Request) throws -> Future<AllProtectedModel> {
        return request.future(error: HotSodaError(abilityType: .update))
    }

    func canDelete(on request: Request) throws -> Future<AllProtectedModel> {
        return request.future(error: HotSodaError(abilityType: .delete))
    }
}

private final class NoProtectedModel: TestModel {
    var id: Int?
    var content: String = ""
}

private final class CreateProtectedModel: TestModel {

    var id: Int?
    var content: String = ""

    static func canCreate(on request: Request) throws -> Future<Void> {
        throw HotSodaError(abilityType: .create)
    }
}

protocol TestModel: SQLiteModel, Migration, AbilityProtected, Parameter, Content {}

extension TestModel {

    static func canCreate(on request: Request) throws -> Future<Void> {
        return request.future(())
    }

    func canRead(on request: Request) throws -> Future<Self> {
        return request.future(self)
    }

    func canUpdate(on request: Request) throws -> Future<Self> {
        return request.future(self)
    }

    func canDelete(on request: Request) throws -> Future<Self> {
        return request.future(self)
    }
}
