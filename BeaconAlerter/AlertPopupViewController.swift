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
import AVFoundation

class AlertPopupViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).container.viewContext
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var snoozeButton: UIButton!
    
    @IBOutlet weak var closeAlertButton: UIButton!
    var alertID: String?
    var alert: Alert?
    
    var player: AVAudioPlayer?
    
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
                    var dateFormat = ""
                    
                    if((UIApplication.shared.delegate as! AppDelegate).getSettings().hourMode == "24"){
                        dateFormat = "HH:mm"
                    }else{
                        dateFormat = "hh:mm a"
                    }
                    dateFormatter.dateFormat = dateFormat
                    let time = dateFormatter.string(from: alert?.time! as! Date)
                    
                    self.timeLabel.text = time
                }
                
            }catch{
                print(error)
            }
            playSound()
            changeSnoozeButtonState()
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playSound() {
        let alertSound = (UIApplication.shared.delegate as! AppDelegate).getSettings().alertSound
        let url = Bundle.main.url(forResource: alertSound, withExtension: "wav")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
            player.volume = Float((UIApplication.shared.delegate as! AppDelegate).getSettings().soundVolume)
            player.numberOfLoops = -1
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound(){
        if let avplayer = player{
            if(avplayer.isPlaying){
                avplayer.pause()
                avplayer.currentTime = 0
                
            }
        }
    }
    
    func changeSnoozeButtonState(){
        let snoozeEnabled = (UIApplication.shared.delegate as! AppDelegate).getSettings().snoozeOn
        let maxSnoozes = (UIApplication.shared.delegate as! AppDelegate).getSettings().snoozeAmount
        
        if(snoozeEnabled){
            if let id = self.alertID{
                if(id.contains("snooze")){
                    let idSplit = id.components(separatedBy: "_")
                    let currentSnoozes = Int(idSplit[2])
                    
                    if(currentSnoozes! < Int(maxSnoozes)){
                        self.snoozeButton.isEnabled = true
                    }else{
                        self.snoozeButton.isEnabled = false
                    }
                }else{
                    self.snoozeButton.isEnabled = true
                }
            }
            
        }else{
            self.snoozeButton.isEnabled = false
        }
        
        print(self.snoozeButton.isEnabled)
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
        stopSound()
        scheduleNooze()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func scheduleNooze(){
        do{
            //Getting sound and snooze length from settings
            let soundName = (UIApplication.shared.delegate as! AppDelegate).getSettings().alertSound!
            let sound = UNNotificationSound.init(named: soundName+".wav")
            let snoozeLength = (UIApplication.shared.delegate as! AppDelegate).getSettings().snoozeLength
            
            let currenttime = Date()
            let calendar = Calendar(identifier: .gregorian)
            let components = calendar.dateComponents(in: .current, from: currenttime)
            
            let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: components.hour, minute: components.minute!+Int(snoozeLength))
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
            
            var snoozeCounter = 0
            if(self.alertID?.contains("snooze"))!{
                let currentSnoozeCount = Int((self.alertID?.components(separatedBy: "_")[2])!)
                snoozeCounter = currentSnoozeCount! + 1
            }else{
                snoozeCounter = 1
            }
            
            let id = (self.alert?.id!)! + "_snooze_\(snoozeCounter)"
            print(id)
            
            let content = UNMutableNotificationContent()
            let title = self.alert?.title ?? " "
            content.title = title
            content.body = "Alert triggered."
            content.sound = sound
            
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) {(error) in
                if let error = error {
                    print("error: \(error)")
                }
            }
            
            print("Snooze for \(id) scheduled")
        }catch{
            print(error)
        }
    }
    
    //Closes the alert and removes one time alerts
    @IBAction func closeAlert(_ sender: Any) {
        stopSound()
        
        if let alertToBeChecked = self.alert{
            if(!alertToBeChecked.repeating){
                (UIApplication.shared.delegate as! AppDelegate).cancelNotification(alert: alertToBeChecked)
                
                do{
                    self.context.delete(alertToBeChecked)
                    try self.context.save()
                }catch{
                    print(error)
                }
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
