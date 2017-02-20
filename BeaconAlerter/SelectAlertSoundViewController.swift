//
//  SelectAlertSoundViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 20.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit

class SelectAlertSoundViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var alertSoundsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.alertSoundsTableView.delegate = self
        self.alertSoundsTableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        // Configure the cell...
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
