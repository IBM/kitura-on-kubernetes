//
//  TransactionsCell.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 6/17/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit

class TransactionsCell: UITableViewCell {

    @IBOutlet weak var transactionTotalPrice: UILabel!
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var transactionId: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
