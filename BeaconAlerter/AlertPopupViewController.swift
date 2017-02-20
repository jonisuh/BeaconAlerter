//
//  AlertPopupViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 16.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class AlertPopupViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).container.viewContext
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var snoozeButton: UIButton!
    
    var alertID: String?
    var alert: Alert?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("alert showing")
        print(self.alertID ?? "No id received")
        (UIApplication.shared.delegate as! AppDelegate).lastPopover = "AlertPopupViewController"
        
        if var id = self.alertID{
            
            if(id.contains("_")){
                var idSplit = id.components(separatedBy: "_")
                id = idSplit[0]
                
                //Removing potential snoozes from notifications
                if(idSplit[1] == "snooze"){
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.alertID!])
                    
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [self.alertID!])
                }
            }
            
            do{
                let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
                alertRequest.predicate = NSPredicate(format: "id == %@", id)
                
                let alerts = try context.fetch(alertRequest) as! [Alert]
                
                if(alerts.count > 0){
                    print("Alert corresponding to \(id) found")
                    self.alert = alerts[0]
                    self.titleLabel.text = alert?.title
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm"
                    let time = dateFormatter.string(from: alert?.time! as! Date)
                    
                    self.timeLabel.text = time
                }
                
            }catch{
                print(error)
            }
        }
        
        // Do any additional setup after loading the view.
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
    
    //MARK: Actions
    @IBAction func snoozeClicked(_ sender: UIButton) {
        //Remember to cancel stuff here
        
        scheduleNooze()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func scheduleNooze(){
        let currenttime = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: currenttime)
        
        //fetch snooze length
        
        //Change to 5
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: components.hour, minute: components.minute!+1)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
        
        let id = (self.alert?.id!)! + "_snooze"
        print(id)
        //Fetch sound
        
        let content = UNMutableNotificationContent()
        let title = self.alert?.title ?? " "
        content.title = title
        content.body = "Alert triggered."
        content.sound = UNNotificationSound.default()
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) {(error) in
            if let error = error {
                print("error: \(error)")
            }
        }
        
        print("Snooze for \(id) scheduled")
    }
}
