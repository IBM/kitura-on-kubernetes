//
//  User.swift
//  Application
//
//  Created by Joe Anthony Peter Amanse on 5/21/18.
//

import Foundation

struct User: Codable {
    var userId: String
    var name: String
    var image: Data
    var steps: Int
    var stepsConvertedToFitcoin: Int
    var fitcoin: Int
    
    init?(userId: String, name: String, image: Data, steps: Int, stepsConvertedToFitcoin: Int, fitcoin: Int) {
        
        self.userId = userId
        self.name = name
        self.image = image
        self.steps = steps
        self.stepsConvertedToFitcoin = stepsConvertedToFitcoin
        self.fitcoin = fitcoin
    }
}

struct UserCompact: Codable {
    var userId: String
    var name: String
    var steps: Int
    var fitcoin: Int
    
    init(_ user: User) {
        self.userId = user.userId
        self.name = user.name
        self.steps = user.steps
        self.fitcoin = user.fitcoin
    }
}

struct AvatarGenerated: Codable {
    var name: String
    var image: String
    
    init?(name: String, image: String) {
        self.name = name
        self.image = image
    }
}
