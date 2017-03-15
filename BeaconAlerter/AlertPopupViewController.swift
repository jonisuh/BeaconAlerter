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
import CoreBluetooth

class AlertPopupViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate{
    
    let context = (UIApplication.shared.delegate as! AppDelegate).container.viewContext
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var snoozeButton: UIButton!
    
    @IBOutlet weak var closeAlertButton: UIButton!
    var alertID: String?
    var alert: Alert?
    
    var player: AVAudioPlayer?
    
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!
    var beaconID: String?
    
    var averageRanges: [Int]!
    var loadingImage: UIImage?
    var closeAlertImage: UIImage?
    
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
            
            
            do{
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
            }catch{
                
                print(error)
            }
            
            playSound()
            changeSnoozeButtonState()
            
            self.manager = CBCentralManager(delegate: self, queue: nil)
            self.beaconID = (UIApplication.shared.delegate as! AppDelegate).getSettings().beaconID
            
            
            
            self.closeAlertButton.isEnabled = false
            let bgImage = UIImage(named: "alert_off_disabled.png")
            self.closeAlertButton.setBackgroundImage(bgImage, for: .normal)
            self.descriptionLabel.text = "Scanning for beacon..."
            averageRanges = [Int]()
            
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
    
    let maxRangeCount = 5;
    func addRangeToAverages(range: Int){
        if(averageRanges.count < maxRangeCount){
            averageRanges.append(range)
        }else{
            for i in 1...maxRangeCount-1{
                averageRanges[i-1] = averageRanges[i]
            }
            averageRanges[maxRangeCount-1] = range
        }
    }
    
    func getCurrentAverageRange() -> Int{
        if(averageRanges.count < maxRangeCount){
            return -1000
        }else{
            var aveTotal = 0
            for ratio in averageRanges{
                aveTotal = aveTotal + ratio
            }
            return aveTotal / averageRanges.count
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
    
    //MARK: Actions
    @IBAction func snoozeClicked(_ sender: UIButton) {
        //Remember to cancel stuff here
        stopSound()
        scheduleNooze()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func scheduleNooze(){
        do{
            self.manager.stopScan()
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
        self.manager.stopScan()
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
    
    //MARK: Bluetooth delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn{
            self.manager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        if let servicedata = advertisementData[CBAdvertisementDataServiceDataKey] as? [NSObject: AnyObject]{
            var eft: BeaconInfo.EddystoneFrameType
            eft = BeaconInfo.frameTypeForFrame(advertisementFrameList: servicedata)
            
            
            if eft == BeaconInfo.EddystoneFrameType.UIDFrameType {
                let telemetry = NSData()
                let serviceUUID = CBUUID(string: "FEAA")
                let _RSSI: Int = RSSI.intValue
                let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
                
                if let beaconServiceData = servicedata[serviceUUID] as? NSData, let beaconInfo = BeaconInfo.beaconInfoForUIDFrameData(frameData: beaconServiceData, telemetry: telemetry, RSSI: _RSSI, deviceName: deviceName){
                    let discoveredBeaconID = BeaconInfo.hexaDecimalString(from: beaconInfo.beaconID.beaconID)
                    
                    
                    if(discoveredBeaconID == self.beaconID){
                        //print(beaconInfo.RSSI)
                        var RSSI = beaconInfo.RSSI
                        var txPower = beaconInfo.txPower
                        
                        addRangeToAverages(range: RSSI)
                        print(getCurrentAverageRange())
                        
                        if(getCurrentAverageRange() > txPower-41){
                            self.closeAlertButton.isEnabled = true
                            let bgImage = UIImage(named: "alert_off_enabled.png")
                            self.closeAlertButton.setBackgroundImage(bgImage, for: .normal)
                            self.descriptionLabel.text = "Beacon found!"
                        }else{
                            /* self.closeAlertButton.isEnabled = false
                            self.descriptionLabel.text = "Scanning for beacon..." */
                        }
                    }
                    
                }else{
                    print("Something went wrong with data parsing")
                }
                
            }else{
                
            }
        }else{
            // print("Can't create service data")
        }
        
    }
}
