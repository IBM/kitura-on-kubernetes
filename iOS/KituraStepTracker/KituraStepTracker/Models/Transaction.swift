//
//  Transaction.swift
//  Application
//
//  Created by Joe Anthony Peter Amanse on 5/22/18.
//

import Foundation

struct Transaction: Codable {
    var transactionId: String
    var productId: String
    var userId: String
    var quantity: Int
    var totalPrice: Int
    
    init?(transactionId: String, productId: String, userId: String, quantity: Int, totalPrice: Int) {
        self.transactionId = transactionId
        self.productId = productId
        self.userId = userId
        self.quantity = quantity
        self.totalPrice = totalPrice
    }
}

struct TransactionRequest: Codable {
    var productId: String
    var userId: String
    var quantity: Int
    
    init(productId: String, userId: String, quantity: Int) {
        self.productId = productId
        self.userId = userId
        self.quantity = quantity
    }
}
