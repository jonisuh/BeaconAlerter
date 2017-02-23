//
//  Alert+CoreDataClass.swift
//  BeaconAlerter
//
//  Created by iosdev on 12.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import Foundation
import CoreData

public class Alert: NSManagedObject {

    
    static func createAlert(title: String, id: String, days: [Bool], time: Date, context: NSManagedObjectContext) -> Alert?{
        
        //Checking if an alert with this id already exists
        let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
        alertRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let alerts = try context.fetch(alertRequest) as! [Alert]
            
            if(alerts.count == 0){
                let alert = NSEntityDescription.insertNewObject(forEntityName: "Alert", into: context) as! Alert
                alert.title = title
                alert.days = days
                alert.time = time as NSDate?
                //Alert has days array specified so it must be repeating
                alert.repeating = true
                alert.isEnabled = true
                return alert
            }else{
                return nil
            }
        }catch{
            print("Error fetching alerts")
            return nil
        }
    }
    
    
    static func createAlert(title: String, id: String, date: Date, context: NSManagedObjectContext) -> Alert?{
        //Checking if an alert with this id already exists
        let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
        alertRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let alerts = try context.fetch(alertRequest) as! [Alert]
            
            if(alerts.count == 0){
                let alert = NSEntityDescription.insertNewObject(forEntityName: "Alert", into: context) as! Alert
                alert.title = title
                alert.id = id
                alert.time = date as NSDate?
                //Alert doesn't have days so it is not repeating
                alert.repeating = false
                alert.isEnabled = true
                return alert
            }else{
                return nil
            }
        }catch{
            print("Error fetching alerts")
            return nil
        }
    }
    
    static func createAlertFrom(json: [String: Any], context: NSManagedObjectContext) -> Alert?{
        //Checking if an alert with this id already exists
        if let title = json["title"] as? String, let id = json["id"] as? String, let time = json["time"] as? String, let repeating = json["repeating"] as? Bool, let isEnabled = json["isEnabled"] as? Bool, let days = json["days"] as? [String: Bool] {
            
            let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
            alertRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let alerts = try context.fetch(alertRequest) as! [Alert]
                var alert: Alert
                
                //Alert does not exist
                if(alerts.count == 0){
                    alert = NSEntityDescription.insertNewObject(forEntityName: "Alert", into: context) as! Alert
                    alert.id = id
                }else{
                //Alert exists
                    alert = alerts[0]
                }
                
                alert.title = title
                alert.time = stringToDate(date: time) as NSDate?
                
                alert.days = [Bool]()
                alert.days?.append(days["mon"]!)
                alert.days?.append(days["tue"]!)
                alert.days?.append(days["wed"]!)
                alert.days?.append(days["thu"]!)
                alert.days?.append(days["fri"]!)
                alert.days?.append(days["sat"]!)
                alert.days?.append(days["sun"]!)
                
                alert.repeating = repeating
                alert.isEnabled = isEnabled
                return alert
                
            }catch{
                print("Error fetching alerts")
                return nil
            }
        }else{
            print("Invalid data")
            return nil
        }
    }
    
    //Generates random ID locally
    static func generateID(context: NSManagedObjectContext) -> String{
        let idRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
        do{
            while(true){
                let id = UUID().uuidString
                idRequest.predicate = NSPredicate(format: "id == %@", id)
                
                let alerts = try context.fetch(idRequest) as! [Alert]
                
                if(alerts.count == 0){
                    return id
                }
            }
        }catch{
            print(error)
        }
        return ""
    }
    
    static func stringToDate(date: String) -> Date {
        let formatter = DateFormatter()
        print(date)
        
        //formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: date)!
    }
    
    static func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        //formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:SSSZ"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter.string(from: date)
    }
}
