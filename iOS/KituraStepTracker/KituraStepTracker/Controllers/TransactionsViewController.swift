//
//  TransactionsViewController.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 6/17/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit
import KituraKit

class TransactionsViewController: UIViewController {

    @IBOutlet weak var transactionsTable: UITableView!
    let cellReuseIdentifier = "transactionCell"
    var transactions: [Transaction]?
    var currentUser: SavedUser?
    let KituraBackendUrl = "https://anthony-dev.us-south.containers.mybluemix.net"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // get current user
        currentUser = (UIApplication.shared.delegate as! AppDelegate).getUserFromLocal()
        
        // initialize class variables
        self.transactions = []
        
        // add shop table delegates
        self.transactionsTable.delegate = self
        self.transactionsTable.dataSource = self
        self.transactionsTable.allowsSelection = false
        self.transactionsTable.tableFooterView = UIView()
        
        // get transactions
        self.getUserTransactions()
    }
    
    func getUserTransactions() {
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            return
        }
        client.get("/shop/transactions/\(self.currentUser!.userId!)")  { (transactions: [Transaction]?, error: Error?) in
            self.transactions = transactions
            DispatchQueue.main.async {
                self.transactionsTable.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TransactionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TransactionsCell = self.transactionsTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! TransactionsCell
        
        cell.productName.text = self.transactions![indexPath.row].productId
        cell.transactionId.text = self.transactions![indexPath.row].transactionId
        cell.transactionTotalPrice.text = String(describing: self.transactions![indexPath.row].totalPrice)
        
        return cell
    }
    
    
}
