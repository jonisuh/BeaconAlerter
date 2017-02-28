//
//  Settings+CoreDataClass.swift
//  BeaconAlerter
//
//  Created by iosdev on 18.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import Foundation
import CoreData

public class Settings: NSManagedObject {
    
    static func createSettings(hourMode: String, dateFormat: String, snoozeOn: Bool, snoozeLength: Int, snoozeAmount: Int, alertSound: String, soundVolume: Double, automaticSync: Bool,beaconID: String, context: NSManagedObjectContext) -> Settings?{
        
        let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
        
        do {
            let settingsResults = try context.fetch(settingsRequest) as! [Settings]
            
            if(settingsResults.count == 0){
                let settings = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: context) as! Settings
                
                settings.hourMode = hourMode
                settings.dateFormat = dateFormat
                settings.snoozeOn = snoozeOn
                settings.snoozeLength = Int32(snoozeLength)
                settings.snoozeAmount = Int32(snoozeAmount)
                settings.alertSound = alertSound
                settings.soundVolume = soundVolume
                settings.automaticSync = automaticSync
                settings.beaconID = beaconID;
                
                return settings
            }else{
                return nil
            }
        }catch{
            print("Error fetching settings")
            return nil
        }
    }
    
    static func settingsHaveChanged(newSettings: [String: Any], oldSettings: Settings) -> Bool{
        if(oldSettings.hourMode != newSettings["hourMode"] as? String){
            return true
        }
        
        if(oldSettings.dateFormat != newSettings["dateFormat"] as? String){
            return true
        }
        
        if(oldSettings.snoozeOn != newSettings["snoozeOn"] as? Bool){
            return true
        }
        
        if(oldSettings.snoozeLength != newSettings["snoozeLength"] as? Int32){
            return true
        }
        
        if(oldSettings.snoozeAmount != newSettings["snoozeAmount"] as? Int32){
            return true
        }
        
        if(oldSettings.soundVolume != newSettings["soundVolume"] as? Double){
            return true
        }
        
        if(oldSettings.alertSound != newSettings["alertSound"] as? String){
            return true
        }
        
        if(oldSettings.automaticSync != newSettings["automaticSync"] as? Bool){
            return true
        }
        
        if(oldSettings.beaconID != newSettings["beaconID"] as? String){
            return true
        }
        return false
    }
}
