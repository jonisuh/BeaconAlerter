//
//  NewAlertViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 11.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreData

class NewAlertViewController: UIViewController, UITextFieldDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).container.viewContext
    var alertToBeEdited: Alert?
    
    var showRepeating = true
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var repeatingView: UIView!
    @IBOutlet weak var onetimeView: UIView!
    
    @IBOutlet weak var changeAlertTypeButton: UIButton!
    @IBOutlet weak var alertTypeLabel: UILabel!
    
    @IBOutlet var dayButtons: [UIButton]!
    @IBOutlet weak var titleField: UITextField!
    
    @IBOutlet weak var repeatingTimePicker: UIDatePicker!
    @IBOutlet weak var oneTimeDatePicker: UIDatePicker!
    
    
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (UIApplication.shared.delegate as! AppDelegate).lastPopover = "NewAlertViewController"
        
        titleField.delegate = self
        
        if let alert = alertToBeEdited{
            titleLabel.text = "Edit alert"
            if(alert.title != "" || alert.title != " " || alert.title != nil){
                titleField.text = alert.title!
            }
            
            if(alert.repeating){
                createAlertModeViews(repeating: true)
                repeatingTimePicker.date = alert.time as! Date
                for i in 0...6{
                    dayButtons[i].isSelected = alert.days![i]
                }
            }else{
                createAlertModeViews(repeating: false)
                oneTimeDatePicker.date = alert.time as! Date
                
            }
            createButton.isEnabled = true
            createButton.setTitle("Save", for: .normal)
        }else{
            createAlertModeViews(repeating: true)
        }
    }

    func createAlertModeViews(repeating: Bool){
        if((UIApplication.shared.delegate as! AppDelegate).getSettings().hourMode == "24"){
            oneTimeDatePicker.locale = Locale.init(identifier: "en_GB")
            repeatingTimePicker.locale = Locale.init(identifier: "en_GB")
        }else{
            oneTimeDatePicker.locale = Locale.init(identifier: "en_US")
            repeatingTimePicker.locale = Locale.init(identifier: "en_US")
        }
        
        if(repeating){
            repeatingView.isHidden = !showRepeating
            onetimeView.isHidden = showRepeating
            
            alertTypeLabel.text = "Create a repeating alert."
            changeAlertTypeButton.setTitle("One time", for: .normal)
            
            createButton.isEnabled = false
            
        }else{
            showRepeating = false
            repeatingView.isHidden = !showRepeating
            onetimeView.isHidden = showRepeating
            
            
            oneTimeDatePicker.minimumDate = NSDate() as Date
            
            alertTypeLabel.text = "Create a one time alert."
            changeAlertTypeButton.setTitle("Repeating", for: .normal)
            createButton.isEnabled = true
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func changeView(_ sender: UIButton) {
        showRepeating = !showRepeating
        
        repeatingView.isHidden = !showRepeating
        onetimeView.isHidden = showRepeating
        
        if showRepeating {
            alertTypeLabel.text = "Create a repeating alert."
            changeAlertTypeButton.setTitle("One time", for: .normal)
            updateCreateButton()
        } else {
            oneTimeDatePicker.minimumDate = NSDate() as Date
            alertTypeLabel.text = "Create a one time alert."
            changeAlertTypeButton.setTitle("Repeating", for: .normal)
            createButton.isEnabled = true
        }
    }
    
    private func updateCreateButton(){
        if(showRepeating){
            var dayIsSelected = false
            for button in dayButtons{
                if(button.isSelected){
                    dayIsSelected = true
                }
            }
            createButton.isEnabled = dayIsSelected
        }
    }
    
    //MARK: Day buttons
    @IBAction func selectEveryDay(_ sender: UIButton) {
        for button in dayButtons{
            button.isSelected = true
        }
        updateCreateButton()
    }
    
    @IBAction func selectDay(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        updateCreateButton()
    }
    
    //MARK: TextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //MARK: Exit
    @IBAction func createNewAlert(_ sender: UIButton) {
        
        do{
            var id = Alert.generateID(context: context)
            var alert: Alert
            
            //If we want to edit an alert we assign the alert variable the alert object we want to edit
            if(alertToBeEdited != nil){
                //editAlert(alert: alert)
                alert = alertToBeEdited!
                id = alert.id!
            }else{
                //Else we create a new alert
               //createNewAlert(id: id)
               alert = NSEntityDescription.insertNewObject(forEntityName: "Alert", into: context) as! Alert
               alert.isEnabled = true
            }
            
            if(showRepeating){
                alert.repeating = true
                
                var days = [Bool]()
                alert.days = days
                for button in dayButtons{
                    days.append(button.isSelected)
                }
                alert.days = days
                
                let calender = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
                let time = repeatingTimePicker.date
                var components = calender.components([.year, .month, .day, .hour, .minute, .second], from: time)
                
                // Change the time to 9:30:00 in your locale
                components.day = 1
                components.month = 1
                components.year = 2000
                
                let date = calender.date(from: components)!
                alert.time = date as NSDate?
            }else{
                alert.repeating = false
                alert.days = nil
                alert.time = oneTimeDatePicker.date as NSDate?
            }
            
            alert.title = titleField.text ?? " "
            alert.id = id
            
            if(alert.isEnabled){
                (UIApplication.shared.delegate as! AppDelegate).rescheduleNotification(alert: alert)
            }
            
            try context.save()
            self.dismiss(animated: true, completion: nil)
        }catch{
            print("Something went wrong with saving new alert")
        }
        
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    


}
