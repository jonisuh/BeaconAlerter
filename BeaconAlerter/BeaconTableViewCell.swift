//
//  BeaconTableViewCell.swift
//  BeaconAlerter
//
//  Created by iosdev on 1.3.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit

class BeaconTableViewCell: UITableViewCell {
    @IBOutlet weak var beaconIDLabel: UILabel!
    @IBOutlet weak var rangeLabel: UILabel!
    @IBOutlet weak var approxRangeTitle: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
