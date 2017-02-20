//
//  AlertTableViewCell.swift
//  BeaconAlerter
//
//  Created by iosdev on 12.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit

class AlertTableViewCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var toggleButton: UISwitch!
    
    @IBOutlet var dayLabels: [UILabel]!
    @IBOutlet weak var stackView: UIStackView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
