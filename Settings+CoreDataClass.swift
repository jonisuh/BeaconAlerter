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
    
    static func createSettings(hourMode: String, dateFormat: String, snoozeOn: Bool, snoozeLength: Int, snoozeAmount: Int, alertSound: String, soundVolume: Double, automaticSync: Bool, context: NSManagedObjectContext) -> Settings?{
        
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
                
                return settings
            }else{
                return nil
            }
        }catch{
            print("Error fetching settings")
            return nil
        }
    }
}
