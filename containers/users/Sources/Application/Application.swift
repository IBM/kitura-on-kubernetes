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

struct UpdateUserStepsRequest: Codable {
    var steps: Int
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
        
        router.get("/users/generate", handler: generateNewAvatar)
        router.post("/users", handler: registerNewUser)
        router.get("/users/complete", handler: getAllUsersFromDB)
        router.get("/users", handler: getAllUsersWithoutImage)
        router.get("/users", handler: getOneUser)
        router.put("/users", handler: updateOneUserSteps)
        
        // set up the table
        Persistence.setUp()
        do {
            try User.createTableSync()
        } catch let error {
            print(error)
        }
    }
    
    func generateNewAvatar(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        let task = URLSession.shared.dataTask(with: URL(string: "http://avatar-rainbow.mybluemix.net/new")!) { (data, res, error) in
            
            if error != nil {
                print(error!.localizedDescription)
                print("No connection")
                next()
                return
            }
            
            do {
                let avatar = try JSONDecoder().decode(AvatarGenerated.self, from: data!)
                try response.status(.OK).send(avatar).end()
                next()
            } catch let jsonError {
                print(jsonError)
                next()
            }
        }
        task.resume()
    }
    
    // somehow, this returns the JSON body AND a 500 code instead of 200
//    func generateNewAvatar(completion: @escaping (AvatarGenerated?, RequestError?) -> Void) {
//        let task = URLSession.shared.dataTask(with: URL(string: "http://avatar-rainbow.mybluemix.net/new")!) { (data, response, error) in
//
//            if error != nil {
//                print(error!.localizedDescription)
//                print("No connection")
//                completion(nil, .notFound)
//                return
//            }
//
//            do {
//                let avatar = try JSONDecoder().decode(AvatarGenerated.self, from: data!)
//                completion(avatar, nil)
//            } catch let jsonError {
//                print(jsonError)
//                completion(nil, .notFound)
//                return
//            }
//        }
//        task.resume()
//    }
    
    func registerNewUser(avatar: AvatarGenerated, completion: @escaping (User?, RequestError?) -> Void) {
        let imageData = Data(base64Encoded: avatar.image, options: .ignoreUnknownCharacters)
        let user = User(userId: UUID.init().uuidString, name: avatar.name, image: imageData!, steps: 0, stepsConvertedToFitcoin: 0, fitcoin: 0)
        
        user?.save(completion)
    }
    
    func getAllUsersFromDB(completion: @escaping ([User]?, RequestError?) -> Void) {
        User.findAll(completion)
    }
    
    func getAllUsersWithoutImage(completion: @escaping ([UserCompact]?, RequestError?) -> Void) {
        var usersCompact: [UserCompact] = []
        User.findAll { users, error in
            for user in users! {
                usersCompact.append(UserCompact(user))
            }
            completion(usersCompact, error)
        }
    }
    
    func getOneUser(id: String, completion: @escaping (User?, RequestError?) -> Void) {
        User.find(id: id, completion)
    }
    
    func updateOneUserSteps(id: String, request: UpdateUserStepsRequest, completion: @escaping (UserCompact?, RequestError?) -> Void) {
        
        // Get the user that should exist in the database
        User.find(id: id) { user, error in
            if let user = user {
                
                // update the user's data (give fitcoins, update stepsConvertedToFitcoin, update new steps)
                // logic gives 1 fitcoin for every 100 steps
                var currentUser = user
                currentUser.steps = request.steps
                let stepsToBeConverted = currentUser.steps - currentUser.stepsConvertedToFitcoin
                currentUser.fitcoin += stepsToBeConverted / 100
                currentUser.stepsConvertedToFitcoin += stepsToBeConverted - (stepsToBeConverted % 100)
                currentUser.update(id: id) { user, error in
                    completion(UserCompact(user!), error)
                }
            }
        }
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
