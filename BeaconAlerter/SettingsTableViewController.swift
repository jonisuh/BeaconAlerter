//
//  SettingsTableViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 18.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreData
class SettingsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).container.viewContext
    
    
    @IBOutlet weak var hourModeButton: UIButton!
    @IBOutlet weak var dateFormatButton: UIButton!
    
    @IBOutlet weak var snoozeSwitch: UISwitch!
    @IBOutlet weak var snoozeLengthLabel: UILabel!
    @IBOutlet weak var snoozeLengthStepper: UIStepper!
    @IBOutlet weak var maxSnoozesLabel: UILabel!
    @IBOutlet weak var maxSnoozesStepper: UIStepper!
    
    
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var alertSoundButton: UIButton!
    
    @IBOutlet weak var syncSwitch: UISwitch!
    
    var settings: Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do{
            let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
            
            self.settings = try (self.context.fetch(settingsRequest) as! [Settings])[0]
            
            updateViews()
        }catch{
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    
    //TODO: Hour/date modes and alert sound
    func updateViews(){
        if let settingsUnwrapped = self.settings{
            //Clock settings
            let dateFormatter = DateFormatter()
            
            dateFormatter.dateFormat = settingsUnwrapped.dateFormat
            let date = dateFormatter.string(from: Date())
            
            hourModeButton.setTitle(settingsUnwrapped.hourMode!+" hours", for: .normal)
            dateFormatButton.setTitle(date, for: .normal)
            
            //Snooze switch config
            snoozeSwitch.isOn = settingsUnwrapped.snoozeOn
            maxSnoozesStepper.isEnabled = settingsUnwrapped.snoozeOn
            snoozeLengthStepper.isEnabled = settingsUnwrapped.snoozeOn
            
            //Snooze length config
            snoozeLengthLabel.text = "\(settingsUnwrapped.snoozeLength) minutes"
            snoozeLengthStepper.value = Double(settingsUnwrapped.snoozeLength)
            
            //Max snoozes config
            maxSnoozesLabel.text = "\(settingsUnwrapped.snoozeAmount)"
            maxSnoozesStepper.value = Double(settingsUnwrapped.snoozeAmount)
            
            //Sound config
            volumeSlider.value = Float(settingsUnwrapped.soundVolume)
            alertSoundButton.setTitle(settingsUnwrapped.alertSound, for: .normal)
            
            //Sync config
            syncSwitch.isOn = settingsUnwrapped.automaticSync
        }
        
    }
    
    //Saves settings to core data
    func saveSettings(){
        do{
            try self.context.save()
        }catch{
            print(error)
        }
    }
    
    //MARK: Actions
    @IBAction func changeHourMode(_ sender: Any) {
        if(self.settings?.hourMode == "12"){
           self.settings?.hourMode = "24"
        }else{
            self.settings?.hourMode = "12"
        }
        updateViews()
        saveSettings()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    @IBAction func snoozeLengthChanged(_ sender: Any) {
        self.settings?.snoozeLength = Int32(self.snoozeLengthStepper.value)
        updateViews()
        saveSettings()
        
        (UIApplication.shared.delegate as! AppDelegate).rescheduleAllNotifications()
    }
    
    @IBAction func maxSnoozesChanged(_ sender: Any) {
        self.settings?.snoozeAmount = Int32(self.maxSnoozesStepper.value)
        updateViews()
        saveSettings()
        
        (UIApplication.shared.delegate as! AppDelegate).rescheduleAllNotifications()
    }
    
    @IBAction func snoozeSwitchChanged(_ sender: Any) {
        self.settings?.snoozeOn = self.snoozeSwitch.isOn
        updateViews()
        saveSettings()
        
        (UIApplication.shared.delegate as! AppDelegate).rescheduleAllNotifications()
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        self.settings?.soundVolume = Double(self.volumeSlider.value)
        updateViews()
        saveSettings()
    }
    
    @IBAction func syncSwitchChanged(_ sender: Any) {
        self.settings?.automaticSync = self.syncSwitch.isOn
        updateViews()
        saveSettings()
    }
    
    
    // MARK: - Table view data source
    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    */
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    //MARK: Popover
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //segue for the popover configuration window
        
        switch segue.identifier!{
        case "selectDateFormat":
            if let controller = segue.destination as? SettingsPickerViewController {
                controller.popoverPresentationController!.delegate = self
                controller.popoverPresentationController!.sourceView = self.view
                controller.popoverPresentationController!.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY-40, width: 0, height: 0)
                controller.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                controller.preferredContentSize = CGSize(width: 260, height: 270)
                
            }
        case "selectAlertSound":
            if let controller = segue.destination as? SelectAlertSoundViewController {
                controller.popoverPresentationController!.delegate = self
                controller.popoverPresentationController!.sourceView = self.view
                controller.popoverPresentationController!.sourceRect = CGRect(x: self.view.bounds.midX-100, y: self.view.bounds.midY-50, width: 0, height: 0)
                controller.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                controller.preferredContentSize = CGSize(width: 450, height: 470)
                
            }
        default:
            print(segue.identifier!)
        }
    }
    func returnFromPopover(){
        updateViews()
        saveSettings()
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        print("Returning from settings")
        if (self.isMovingFromParentViewController){
            if((UIApplication.shared.delegate as! AppDelegate).getSettings().automaticSync){
                (UIApplication.shared.delegate as! AppDelegate).postSettingsToServer()
            }
        }
    }

}
