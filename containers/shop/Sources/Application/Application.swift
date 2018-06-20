import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import SwiftKuery
import SwiftKueryORM
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

extension Product: Model {
    static var idColumnName = "productId"
}

extension Transaction: Model {
    static var idColumnName = "transactionId"
}

extension User: Model {
    static var idColumnName = "userId"
}

struct TransactionFilter: QueryParams {
    var userId: String
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

struct CustomRequestError: Codable {
    var reason: String?
    
    init?(_ reason: String) {
        self.reason = reason
    }
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    
    let notEnoughFitcoinsError = RequestError.init(RequestError.notFound, body: CustomRequestError.init("User does not have enough fitcoins."))

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        router.get("/shop/products", handler: getAllProducts)
        router.get("/shop/products", handler: getOneProduct)
        router.post("/shop/products", handler: addProduct)
        router.put("/shop/products", handler: updateProduct)
        router.get("/shop/transactions", handler: getAllTransactions)
        router.get("/shop/transactions", handler: getOneTransaction)
        router.get("/shop/transactions", handler: getTransactionsOfUser)
        router.post("/shop/transactions", handler: newTransaction)
        
        Persistence.setUp()
        do {
            try Product.createTableSync()
            try Transaction.createTableSync()
        } catch let error {
            print(error)
        }
    }
    
    func getAllProducts(completion: @escaping ([Product]?, RequestError?) -> Void) {
        Product.findAll(completion)
    }
    
    func getOneProduct(id: String, completion: @escaping (Product?, RequestError?) -> Void) {
        Product.find(id: id, completion)
    }
    
    func addProduct(product: Product, completion: @escaping (Product?, RequestError?) -> Void) {
        product.save(completion)
    }
    
    func updateProduct(id: String, updatedProduct: Product, completion: @escaping (Product?, RequestError?) -> Void) {
        Product.find(id: id) { product, error in
            guard product != nil else {
                completion(nil, .notFound)
                return
            }
            updatedProduct.update(id: id, completion)
        }
    }
    
    func getAllTransactions(completion: @escaping ([Transaction]?, RequestError?) -> Void) {
        Transaction.findAll(completion)
    }
    
    func getOneTransaction(id: String, completion: @escaping (Transaction?, RequestError?) -> Void) {
        Transaction.find(id: id, completion)
    }
    
    func getTransactionsOfUser(id: String, completion: @escaping ([Transaction]?, RequestError?) -> Void) {
        let filter = TransactionFilter.init(userId: id)
        Transaction.findAll(matching: filter, completion)
    }
    
    func newTransaction(transactionRequest: TransactionRequest, completion: @escaping (Transaction?, RequestError?) -> Void) {
        
        // Get the product that should exist in the database
        Product.find(id: transactionRequest.productId) { product, error in
            guard let product = product else {
                completion(nil, .notFound)
                return
            }
            
            // Get the user that should exist in the database
            User.find(id: transactionRequest.userId) { user, error in
                guard let user = user else {
                    completion(nil, .notFound)
                    return
                }
                
                // Get the total price of the purchase
                let totalPrice: Int = product.price * transactionRequest.quantity
                
                // Make sure that user has enough fitcoins
                if user.fitcoin >= totalPrice {
                    
                    // Create a transaction
                    let transaction: Transaction = Transaction(transactionId: UUID.init().uuidString, productId: product.productId, userId: user.userId, quantity: transactionRequest.quantity, totalPrice: totalPrice)!
                    transaction.save() { transaction, error in
                        
                        // update the user's fitcoins
                        var updatedUser = user
                        updatedUser.fitcoin -= totalPrice
                        updatedUser.update(id: user.userId) { user, error in
                            guard user != nil else {
                                completion(nil, .notFound)
                                return
                            }
                            completion(transaction, error)
                        }
                    }
                } else {
                    completion(nil, self.notEnoughFitcoinsError)
                    return
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
