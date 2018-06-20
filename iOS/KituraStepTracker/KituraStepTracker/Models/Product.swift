//
//  Product.swift
//  Application
//
//  Created by Joe Anthony Peter Amanse on 5/22/18.
//

import Foundation

struct Product: Codable {
    var productId: String
    var name: String
    var quantity: Int
    var price: Int
    
    init?(productId: String, name: String, quantity: Int, price: Int) {
        self.productId = productId
        self.name = name
        self.quantity = quantity
        self.price = price
    }
}
