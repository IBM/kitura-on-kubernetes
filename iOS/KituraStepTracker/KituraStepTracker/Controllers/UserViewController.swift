//
//  FirstViewController.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 5/23/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit
import KituraKit
import CoreData
import HealthKit
import CoreMotion

struct UpdateUserStepsRequest: Codable {
    var steps: Int
}

class UserViewController: UIViewController {

    @IBOutlet weak var userFitcoins: UILabel!
    @IBOutlet weak var userSteps: UILabel!
    @IBOutlet weak var userScrollView: UIScrollView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userId: UILabel!
    var refreshControl: UIRefreshControl?
    let KituraBackendUrl = "https://anthony-dev.us-south.containers.mybluemix.net"
    var sendingInProgress: Bool = false
    
    var pedometer = CMPedometer()
    var currentUser: SavedUser?
    var userBackend: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Clear labels
        self.userName.text = ""
        self.userId.text = ""
        self.userSteps.text = ""
        self.userFitcoins.text = ""
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.userScrollView.refreshControl = refreshControl
        
        currentUser = (UIApplication.shared.delegate as! AppDelegate).getUserFromLocal()
        self.getCurrentSteps()
        self.startUpdatingSteps()
        
        if let user = currentUser {
            self.getUserWith(userId: user.userId!)
        }
    }
    
    func getUserWith(userId: String, group: DispatchGroup? = nil) {
        group?.enter()
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            group?.leave()
            return
        }
        
        client.get("/users/\(userId)") { (user: User?, error: Error?) in
            guard error == nil else {
                print("Error getting user from Kitura: \(error!)")
                group?.leave()
                return
            }
            
            if let user = user {
                print(user)
                self.userBackend = user
                self.updateViewWith(userId: user.userId, name: user.name, image: user.image, fitcoins: user.fitcoin)
            }
            
            group?.leave()
        }
    }
    
    func updateViewWith(userId: String, name: String, image: Data, fitcoins: Int) {
        DispatchQueue.main.async {
            self.userId.text = userId
            self.userName.text = name
            self.userImage.image = UIImage(data: image)
            self.userFitcoins.text = "\(fitcoins) fitcoins"
            self.userImage.layer.cornerRadius = 75
        }
    }
    
    func getCurrentSteps(_ group: DispatchGroup? = nil) {
        group?.enter()
        if let user = self.currentUser {
            pedometer.queryPedometerData(from: user.startDate!, to: Date()) { (pedometerData, error) in
                if let error = error {
                    print(error)
                }
                
                if let pedometerData = pedometerData {
                    DispatchQueue.main.async {
                        self.userSteps.text = String(describing: pedometerData.numberOfSteps) + " steps"
                    }
                }
                group?.leave()
            }
        } else {
            group?.leave()
        }
    }
    
    func startUpdatingSteps(_ group: DispatchGroup? = nil) {
        group?.enter()
        
        if let user = self.currentUser {
            pedometer.startUpdates(from: user.startDate!) { (pedometerData, error) in
                if let error = error {
                    print(error)
                }
                
                if let pedometerData = pedometerData {
                    DispatchQueue.main.async {
                        self.userSteps.text = String(describing: pedometerData.numberOfSteps) + " steps"
                    }
                    
                    if let userBackend = self.userBackend {
                        if self.sendingInProgress == false {
                            if (pedometerData.numberOfSteps.intValue - userBackend.stepsConvertedToFitcoin) >= 100 {
                                print("ready to send")
                                self.sendingInProgress = true
                                
                                // insert function here to PUT to kitura
                                self.updateUserSteps(userId: userBackend.userId, steps: pedometerData.numberOfSteps.intValue)
                            }
                        }
                    }
                }
                group?.leave()
            }
        } else {
            group?.leave()
        }
    }
    
    func updateUserSteps(userId: String, steps: Int) {
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            self.sendingInProgress = false
            return
        }
        
        client.put("/users", identifier: userId, data: UpdateUserStepsRequest(steps: steps)) { (userCompact: UserCompact?, error: RequestError?) in
            guard error == nil else {
                print("Error getting user from Kitura: \(error!)")
                self.sendingInProgress = false
                return
            }
            
            if let user = userCompact {
                self.getUserWith(userId: user.userId)
            }
            
            self.sendingInProgress = false
        }
    }
    
    @objc func refresh() {
        if let user = self.currentUser {
            // refresh data
            
            let group = DispatchGroup()
            
            getUserWith(userId: user.userId!, group: group)
            getCurrentSteps(group)
            
            group.notify(queue: .main) {
                DispatchQueue.main.async {
                    if (self.refreshControl?.isRefreshing)! {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        } else {
            self.currentUser = (UIApplication.shared.delegate as! AppDelegate).getUserFromLocal()
            DispatchQueue.main.async {
                if (self.refreshControl?.isRefreshing)! {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

