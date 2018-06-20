import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import SwiftKueryORM
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

extension User: Model {
    static var idColumnName = "userId"
}

struct UserPosition: Codable {
    var userPosition: Int
    var numberOfUsers: Int
    var userSteps: Int
}

class Persistence {
    static func setUp() {
        let postgresHOST = ProcessInfo.processInfo.environment["POSTGRES_HOST"] ?? "localhost"
        let postgresPORT = Int(ProcessInfo.processInfo.environment["POSTGRES_PORT"] ?? "5432")
        let postgresUSER = ProcessInfo.processInfo.environment["POSTGRES_USER"] ?? "postgres"
        let postgresPASSWORD = ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"] ?? ""
        let postgresDATABASE = ProcessInfo.processInfo.environment["POSTGRES_DB"] ?? "KituraMicroservices"
        
        let pool = PostgreSQLConnection.createPool(host: postgresHOST, port: Int32(postgresPORT!), options: [.databaseName(postgresDATABASE), .userName(postgresUSER), .password(postgresPASSWORD)], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
        Database.default = Database(pool)
    }
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        
        router.get("/leaderboard", handler: getAllUsersSorted)
        router.get("/leaderboard/user", handler: getUserPosition)
        
        Persistence.setUp()
    }
    
    func getAllUsersSorted(completion: @escaping ([User]?, RequestError?) -> Void) {
        User.findAll { users, error in
            completion(users?.sorted(by: { $0.steps > $1.steps }), error)
        }
    }
    
    func getUserPosition(id: String, completion: @escaping (UserPosition?, RequestError?) -> Void) {
        User.findAll { users, error in
            guard let users = users else {
                completion(nil, .notFound)
                return
            }
            
            User.find(id: id) { user, error in
                guard let user = user else {
                    completion(nil, .notFound)
                    return
                }
                
                completion(UserPosition(userPosition: users.filter{$0.steps > user.steps}.count + 1, numberOfUsers: users.count, userSteps: user.steps), error)
            }
        }
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
