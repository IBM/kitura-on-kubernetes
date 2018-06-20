//
//  SecondViewController.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 5/23/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit
import KituraKit

struct CustomRequestError: Codable {
    var reason: String?
    
    init?(_ reason: String) {
        self.reason = reason
    }
}

class ShopViewController: UIViewController {

    @IBOutlet weak var shopTable: UITableView!
    
    var refreshControl: UIRefreshControl?
    let cellReuseIdentifier = "productCell"
    var products: [Product]?
    var currentUser: SavedUser?
    let KituraBackendUrl = "https://anthony-dev.us-south.containers.mybluemix.net"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // get current user
        self.currentUser = appDelegate.getUserFromLocal()
        
        // initialize class variables
        self.products = []
        
        // add shop table delegates
        self.shopTable.delegate = self
        self.shopTable.dataSource = self
        self.shopTable.tableFooterView = UIView()
        
        // add refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(getProducts), for: .valueChanged)
        self.shopTable.refreshControl = refreshControl
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.getProducts()
    }
    
    @objc func getProducts() {
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            return
        }
        client.get("/shop/products") { (products: [Product]?, error: Error?) in
            self.products = products
            DispatchQueue.main.async {
                self.shopTable.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    func purchaseOneProduct(_ product: Product?) -> (_ action: UIAlertAction) -> () {
        return { _ in
            guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
                print("Error creating KituraKit client")
                return
            }
            
            let transactionRequest = TransactionRequest(productId: product!.productId, userId: self.currentUser!.userId!, quantity: 1)
            client.post("/shop/transactions", data: transactionRequest) { (transaction: Transaction?, error: RequestError?) in
                
                // can't get response body in error.bodyAs? to provide rich alert
                if error != nil {
                    self.appDelegate.showAlertWith(title: "Something went wrong...", message: "Either the server is down or you don't have enough fitcoins.", preferredStyle: .alert, action: UIAlertAction(title: "Okay", style: .default, handler: nil))
                    return
                }
                
                if let transaction = transaction {
                    self.appDelegate.showAlertWith(title: "Purchase successful!", message: "You have successfully purchased a \(product!.name). Transaction ID is:\n\(transaction.transactionId)", preferredStyle: .alert, action: UIAlertAction(title: "Okay", style: .default, handler: nil))
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ShopViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.products!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ShopProductCell = self.shopTable.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! ShopProductCell
        
        cell.productName.text = self.products![indexPath.row].name
        cell.productPrice.text = String(describing: self.products![indexPath.row].price)
        cell.productQuantity.text = "\(self.products![indexPath.row].quantity) left"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shopTable.cellForRow(at: indexPath)?.setSelected(false, animated: true)
        appDelegate.showAlertWith(title: "Purchase Confirmation", message: "Do you want to purchase \(self.products![indexPath.row].name)?\nIt costs \(self.products![indexPath.row].price) fitcoins.", preferredStyle: .actionSheet, action: UIAlertAction(title: "Confirm purchase", style: .default, handler: purchaseOneProduct(self.products![indexPath.row])), UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
}

