//
//  MoreActionsViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 13.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit

class MoreActionsViewController: UIViewController {

    @IBOutlet weak var settingsButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        (UIApplication.shared.delegate as! AppDelegate).lastPopover = "MoreActionsViewController"
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func settingsButtonClicked(_ sender: UIButton) {
        let delegate = self.popoverPresentationController!.delegate as? AlertTableViewController
        self.dismiss(animated: true, completion: {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsTableViewController
            delegate?.navigationController?.pushViewController(vc!, animated: true)
        })
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
