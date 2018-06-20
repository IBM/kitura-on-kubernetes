//
//  LeaderboardViewController.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 5/29/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit
import KituraKit

struct UserPosition: Codable {
    var userPosition: Int
    var numberOfUsers: Int
    var userSteps: Int
}

class LeaderboardViewController: UIViewController {

    @IBOutlet weak var leaderboardTable: UITableView!
    
    var refreshControl: UIRefreshControl?
    var users: [User]?
    var currentUser: SavedUser?
    var userPosition: UserPosition?
    let cellReuseIdentifier = "userCell"
    let KituraBackendUrl = "https://anthony-dev.us-south.containers.mybluemix.net"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get current user
        self.currentUser = (UIApplication.shared.delegate as! AppDelegate).getUserFromLocal()
        
        // initialize class variables
        self.users = []
        self.userPosition = UserPosition(userPosition: 0, numberOfUsers: 0, userSteps: 0)
        
        // add delegates and datasource for leaderboard table
        self.leaderboardTable.delegate = self
        self.leaderboardTable.dataSource = self
        self.leaderboardTable.allowsSelection = false
        self.leaderboardTable.tableFooterView = UIView()
        
        // add refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(getLeaderboard), for: .valueChanged)
        self.leaderboardTable.refreshControl = refreshControl
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getLeaderboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc private func getLeaderboard() {
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            return
        }
        client.get("/leaderboard") { (users: [User]?, error: Error?) in
            guard error == nil else {
                print("Error getting leaderboard from Kitura: \(error!)")
                return
            }
            guard let users = users else {
                self.users = [User]()
                return
            }
            self.users = users
            
            
            if let user = self.currentUser {
                client.get("/leaderboard/user/\(user.userId!)") { (userPosition: UserPosition?, error: Error?) in
                    self.userPosition = userPosition
                    
                    DispatchQueue.main.async {
                        self.leaderboardTable.reloadData()
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
}

extension LeaderboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    // build user cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:LeaderboardUserCell = self.leaderboardTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! LeaderboardUserCell
        
        cell.userPosition.text = String(describing: indexPath.row + 1)
        cell.userName.text = self.users![indexPath.row].name
        cell.userSteps.text = "\(self.users![indexPath.row].steps) steps"
        cell.userImage.image = UIImage(data: self.users![indexPath.row].image)
        cell.userImage.layer.cornerRadius = 50
        
        return cell
    }
    
    // build header cell
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell:LeaderboardUserHeaderCell = self.leaderboardTable.dequeueReusableCell(withIdentifier: "userHeaderCell") as! LeaderboardUserHeaderCell
        
        if let user = self.currentUser {
            cell.userImage.image = UIImage(data: user.avatar!)
            cell.userName.text = user.name
        } else {
            cell.userImage.image = nil
            cell.userName.text = ""
        }
        
        if let userPosition = self.userPosition {
            cell.userSteps.text = "\(userPosition.userSteps) steps"
            cell.userPosition.text = "You are position \(userPosition.userPosition) of \(userPosition.numberOfUsers)"
        } else {
            cell.userSteps.text = ""
            cell.userPosition.text = ""
        }
        
        cell.userImage.layer.cornerRadius = 50
        
        return cell
    }
    
    
}
