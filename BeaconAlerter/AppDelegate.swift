//
//  AppDelegate.swift
//  BeaconAlerter
//
//  Created by iosdev on 11.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var lastPopover: String?
    var container = NSPersistentContainer(name: "Model")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            //print("loadPersistentStores() completionHandler")
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Persistent container created.")
            }
        })
        
        UNUserNotificationCenter.current().delegate = self
        
        var userAcceptedNotifications = false
        while(!userAcceptedNotifications){
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {(accepted, error) in
                if !accepted {
                    print("Notification access denied.")
                    let alert = UIAlertController(title: "Notification access denied", message: "You have denied access to notifications. The app heavily depends on notification usage. Please allow the app to use notifications in order to ensure the app works correctly.", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
                userAcceptedNotifications = accepted
            }
        }
        
        do{
            let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
            let settingsResults = try container.viewContext.fetch(settingsRequest) as? [Settings]
            
            if(settingsResults?.count == 0){
                self.initializeSettingsSingleton()
            }
            
        }catch{
            print(error)
        }
        
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //completionHandler(UNNotificationPresentationOptions.alert)
        print("alert")
        showAlert(notification: notification)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        completionHandler()
        
        showAlert(notification: response.notification)
        
        
    }
    //TODO: Fix optionals
    func showAlert(notification: UNNotification){
    
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
        
        let navigationController = self.window?.rootViewController
        let delegate = navigationController?.childViewControllers[0]
        
        let alertPopupController = delegate?.storyboard?.instantiateViewController(withIdentifier: "AlertPopupViewController") as? AlertPopupViewController
        alertPopupController?.modalPresentationStyle = .popover;
        alertPopupController?.preferredContentSize = CGSize(width: 600, height: 400)
        
        let popover = alertPopupController?.popoverPresentationController
        
        popover?.sourceView = delegate?.view
        popover?.sourceRect = CGRect(x: delegate!.view.bounds.midX-100, y: delegate!.view.bounds.midY-50, width: 0, height: 0)
        popover?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        popover?.delegate = delegate as! UIPopoverPresentationControllerDelegate?
        
        alertPopupController?.alertID = notification.request.identifier
        
        delegate!.present(alertPopupController!, animated: true, completion: nil)
    }
    
    private func initializeSettingsSingleton(){
        do{
            let settings = Settings.createSettings(hourMode: "24", dateFormat: "dd MMM yyyy", snoozeOn: true, snoozeLength: 5, snoozeAmount: 1, alertSound: "clock", soundVolume: 1.0, automaticSync: true, context: self.container.viewContext)
            print("Settings initialized")
            
            try self.container.viewContext.save()
        }catch{
            print(error)
        }
    }
    
    func getSettings() -> Settings{
        do{
            let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
            return (try self.container.viewContext.fetch(settingsRequest) as! [Settings])[0]
        }catch{
            print(error)
        }
        //returns empty settings
        return Settings()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.synchronizeDeviceWithServer(notifyUser: false)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: Notifications
    func scheduleNotification(alert: Alert) {

        
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: alert.time! as Date)
        
        func addNotificationToCenter(notificationTrigger: UNCalendarNotificationTrigger, id: String){
                
            let soundName = getSettings().alertSound!
            let sound = UNNotificationSound.init(named: soundName+".wav")

            print("adding")
            print(notificationTrigger.nextTriggerDate() ?? "Trigger date not found")
            
            let content = UNMutableNotificationContent()
            content.title = alert.title!
            content.body = "Alert triggered."
            content.sound = sound
            
            let request = UNNotificationRequest(identifier: id, content: content, trigger: notificationTrigger)

            UNUserNotificationCenter.current().add(request) {(error) in
                if let error = error {
                    print("error: \(error)")
                }
            }
        }
        
        
        var trigger: UNCalendarNotificationTrigger
        var newComponents: DateComponents
        
        var everyDaySelected = false
        if let days = alert.days{
            everyDaySelected = true
            for day in days{
                if(!day){
                    everyDaySelected = false
                }
            }
        }
        
        if(everyDaySelected){
            print("everyday scheduled")
            newComponents = DateComponents()
            newComponents.hour = components.hour
            newComponents.minute = components.minute
            //Debug
            let debugdate = Date()
            let debugcomponents = calendar.dateComponents(in: .current, from: debugdate)
            
            newComponents.second = debugcomponents.second!+3
            
            
            newComponents.timeZone = .current
            trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: true)
            
            addNotificationToCenter(notificationTrigger: trigger, id: alert.id!)
        }else if(alert.repeating){
            print("repeating scheduled")
            for i in 0...6{
                if(alert.days![i]){
                    newComponents = DateComponents()
                    newComponents.hour = components.hour
                    newComponents.minute = components.minute
                    
                    //converting 0-6 weekdays into DateComponents weekday format
                    if(i != 6){
                        newComponents.weekday = i+2
                    }else{
                        newComponents.weekday = 1
                    }
                    
                    newComponents.timeZone = .current
                    trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: true)
                    
                    let id = alert.id! + "_\(i+1)"
                    print(id)
                    addNotificationToCenter(notificationTrigger: trigger, id: id)
                }
            }
        }else{
            print("onetime scheduled")
            newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: components.hour, minute: components.minute)
            
            trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
            addNotificationToCenter(notificationTrigger: trigger, id: alert.id!)
        }
    }
    
    //Cancels all notifications for the given alert
    func cancelNotification(alert: Alert){
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
            print("alert cancelled")
            let results = requests.filter { $0.identifier.contains(alert.id!)}
            //Storing the identifiers which match the alerts UUID into an array
            var identifiers = [String]()
            for result in results{
                print(result.identifier)
                identifiers.append(result.identifier)
            }
            //Clearing notifications with the identifier array
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            
            semaphore.signal()
        })
        
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
            print("Current notification count: \(requests.count)")
        })
        
    }
    //Reschedules an alerts notification
    func rescheduleNotification(alert: Alert){
        cancelNotification(alert: alert)
        scheduleNotification(alert: alert)
    }
    
    //Reschedules all alert notifications
    func rescheduleAllNotifications(){
            
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                do{
                    let settingsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
                    let settings = (try self.container.viewContext.fetch(settingsRequest) as! [Settings])[0]
                    
                    let soundName = settings.alertSound!
                    print(soundName)
                    let sound = UNNotificationSound.init(named: soundName+".wav")
                    
                    for request in requests{
                        if(request.identifier.contains("snooze") && self.getSettings().snoozeOn){
                            var idSplit = request.identifier.components(separatedBy: "_")
                            let id = idSplit[0]
                            let currentSnoozeCount = Int(idSplit[2])
                            
                            
                            let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
                            alertRequest.predicate = NSPredicate(format: "id == %@", id)
                            let alerts = try self.container.viewContext.fetch(alertRequest) as! [Alert]
                            
                            if(alerts.count == 1){
                                let alert = alerts[0]
                                
                                let trigger = request.trigger as! UNCalendarNotificationTrigger
                                
                                let calendar = Calendar(identifier: .gregorian)
                                let components = calendar.dateComponents(in: .current, from: alert.time! as Date)
                                
                                var newHours = components.hour!
                                var newMinutes = components.minute!
                                
                                let snoozeMinutes = currentSnoozeCount! * Int(settings.snoozeLength)
                                let snoozePlusOriginal = newMinutes + snoozeMinutes
                                
                                if(snoozePlusOriginal > 60){
                                    newHours = newHours + 1
                                    newMinutes = snoozePlusOriginal - 60
                                }else{
                                    newMinutes = snoozePlusOriginal
                                }
                                
                                var newComponents = DateComponents()
                                newComponents.minute = newMinutes
                                newComponents.hour = newHours
                                newComponents.calendar = trigger.dateComponents.calendar
                                newComponents.timeZone = trigger.dateComponents.timeZone
                                newComponents.day = trigger.dateComponents.day
                                newComponents.month = trigger.dateComponents.month
                                newComponents.year = trigger.dateComponents.year
                                
                                let newTrigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: trigger.repeats)
                                
                                let content = UNMutableNotificationContent()
                                content.title = request.content.title
                                content.body = "Alert triggered."
                                content.sound = sound
                                
                                let request = UNNotificationRequest(identifier: request.identifier, content: content, trigger: newTrigger)
                                
                                UNUserNotificationCenter.current().add(request) {(error) in
                                    if let error = error {
                                        print("error: \(error)")
                                    }
                                }
                            }
                            
                        }else{
                            let trigger = request.trigger
                            let content = UNMutableNotificationContent()
                            content.title = request.content.title
                            content.body = "Alert triggered."
                            content.sound = sound
                            
                            let request = UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)
                            
                            UNUserNotificationCenter.current().add(request) {(error) in
                                if let error = error {
                                    print("error: \(error)")
                                }
                            }
                        }
                    }
                    
                    
                }catch{
                    print(error)
                }
            })
        
    }
    
    func alertCanBeScheduled(alertsRequired: Int) -> Bool{
        let currentCount = getRequiredNotificationCount()
        
        //Current + required + snooze
        if((currentCount + alertsRequired + 1 ) <= 64){
            return true
        }else{
            return false
        }
        
    }
    
    func getRequiredNotificationCount() -> Int{
        let semaphore = DispatchSemaphore(value: 0)
        var count = 0
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
            for request in requests{
                if(!request.identifier.contains("snooze")){
                    count += 1
                }
            }
            do{
                let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
                let alerts = try self.container.viewContext.fetch(alertRequest) as! [Alert]
                
                count += alerts.count
                
            }catch{
                print(error)
            }
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return count
    }
    
    //MARK: Networking - synchronizing
    func synchronizeDeviceWithServer(notifyUser: Bool){
        self.showSyncToUser = notifyUser
        self.updateSyncAlert(amount: 0)
        self.getSettingsFromServer()
        self.getAlertsFromServer()
    }
    
    
    var alert = UIAlertController()
    var syncPercentage = 0
    var showSyncToUser = false
    func updateSyncAlert(amount: Int){
        if(showSyncToUser){
            if(amount == 0){
                self.alert = UIAlertController(title: "Synchronizing...", message: "", preferredStyle: .alert)
                
                self.window?.rootViewController?.present(self.alert, animated: true, completion: nil)
            }
            
            syncPercentage = syncPercentage + amount
            self.alert.message = "Synchronization at \(syncPercentage)%"
     
            if(self.syncPercentage == 100){
                self.alert.dismiss(animated: false, completion: {
                    self.syncPercentage = 0
                    self.alert = UIAlertController(title: "Synchronization", message: "Synchronization complete. Settings and alerts may have been modified on your device during the synchronization.", preferredStyle: .alert)
                    
                    self.alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.window?.rootViewController?.present(self.alert, animated: true, completion: nil)
                })
            }
        }
    }
    
    //MARK: Networking - alerts
    func postAlertToServer(alert: Alert){
        let urlString = "http://beaconalerter.herokuapp.com/api/alerts"
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
    
                
        let body = generateJSON(dict: getAlertAsDictionary(alert: alert))
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request, completionHandler: {( data, response, error) in
            if let httpResponse = response as? HTTPURLResponse{
                print("Posted alert \(alert.id!) to server with code: \(httpResponse.statusCode)")
                if let error = error {
                    print(error)
                }
            }
        }).resume()
            
        
    }
    
    //Posts all alerts to server
    func postAlertsToServer(){
        let urlString = "http://beaconalerter.herokuapp.com/api/alerts/all"
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        do{
            let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
            let alerts = try self.container.viewContext.fetch(alertRequest) as! [Alert]
            
            var alertsDictionaryArray = [[String: Any]]()
            for alert in alerts{
                alertsDictionaryArray.append(getAlertAsDictionary(alert: alert))
            }
            
            let json = ["alerts":alertsDictionaryArray]
            
            
            let body = generateJSON(dict: json)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            session.dataTask(with: request, completionHandler: {( data, response, error) in
                if let httpResponse = response as? HTTPURLResponse{
                    print("Posted all alerts to server with code: \(httpResponse.statusCode)")
                    if let error = error {
                        print(error)
                    }
                }
            }).resume()
            
        }catch{
            print(error)
        }
        
    }
    
    func getAlertsFromServer(){
        let urlString = "http://beaconalerter.herokuapp.com/api/alerts/"
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request, completionHandler: {( data, response, error) in
            if let httpResponse = response as? HTTPURLResponse{
                print("Queried alerts from server with code: \(httpResponse.statusCode)")
                if let error = error {
                    print(error)
                }else{
                    do{
                        DispatchQueue.main.async {self.updateSyncAlert(amount: 15)}
                        if let alertsDictionary = self.getDictionaryFromJSON(data: data){
                            for item in alertsDictionary{
                                if let singleAlertDictionary = item as? [String: Any]{
                                    Alert.createAlertFrom(json: singleAlertDictionary, context: self.container.viewContext)
                                }
                            }
                            try self.container.viewContext.save()
                            self.postAlertsToServer()
                            DispatchQueue.main.async {self.updateSyncAlert(amount: 15)}
                        }
                        DispatchQueue.main.async {self.updateSyncAlert(amount: 20)}
                    }catch{
                        print(error)
                    }
                }
            }
        }).resume()
    }
    
    func deleteAlertFromServer(alert: Alert){
        let urlString = "http://beaconalerter.herokuapp.com/api/alerts/"+alert.id!
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "DELETE"
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request, completionHandler: {( data, response, error) in
            if let httpResponse = response as? HTTPURLResponse{
                print("Deleted alert \(alert.id!) from server with code: \(httpResponse.statusCode)")
                if let error = error {
                    print(error)
                }
            }
        }).resume()
    }
    
    
    func updateAlertInServer(alert: Alert){
        let urlString = "http://beaconalerter.herokuapp.com/api/alerts/"+alert.id!
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"
        
        
        let body = generateJSON(dict: getAlertAsDictionary(alert: alert))
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request, completionHandler: {( data, response, error) in
            if let httpResponse = response as? HTTPURLResponse{
                print("Updated alert \(alert.id!) in server with code: \(httpResponse.statusCode)")
                if let error = error {
                    print(error)
                }
            }
        }).resume()
    }
    
    
    //MARK: Networking - settings
    
    func getSettingsFromServer(){
        let urlString = "http://beaconalerter.herokuapp.com/api/settings/"
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request, completionHandler: {( data, response, error) in
            if let httpResponse = response as? HTTPURLResponse{
                print("Queried settings from server with code: \(httpResponse.statusCode)")
                if let error = error {
                    print(error)
                }else{
                    DispatchQueue.main.async {self.updateSyncAlert(amount: 15)}
                    if let settingsData = self.getDictionaryFromJSON(data: data){
                        
                        for item in settingsData{
                            
                            if let settingsDictionary = item as? [String: Any]{
                                
                                do{
                                    let settings = self.getSettings()
                                    if(Settings.settingsHaveChanged(newSettings: settingsDictionary, oldSettings: settings)){
                                        settings.alertSound = settingsDictionary["alertSound"] as? String
                                        settings.soundVolume = (settingsDictionary["soundVolume"] as? Double)!
                                        settings.snoozeOn = (settingsDictionary["snoozeOn"] as? Bool)!
                                        settings.snoozeAmount = (settingsDictionary["snoozeAmount"] as? Int32)!
                                        settings.snoozeLength = (settingsDictionary["snoozeLength"] as? Int32)!
                                        settings.hourMode = settingsDictionary["hourMode"] as? String
                                        settings.dateFormat = settingsDictionary["dateFormat"] as? String
                                        settings.automaticSync = (settingsDictionary["automaticSync"] as? Bool)!
                                        
                                        try self.container.viewContext.save()
                                    }
                                    DispatchQueue.main.async {self.updateSyncAlert(amount: 15)}
                                }catch{
                                    print(error)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {self.updateSyncAlert(amount: 20)}
                }
            }
        }).resume()
    }
    
    func postSettingsToServer(){
        let urlString = "http://beaconalerter.herokuapp.com/api/settings"
        let url = URL(string: urlString)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        
        let body = generateJSON(dict: getSettingsAsDictionary())
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request, completionHandler: {( data, response, error) in
            if let httpResponse = response as? HTTPURLResponse{
                print("Posted settings to server with code: \(httpResponse.statusCode)")
                if let error = error {
                    print(error)
                }
            }
        }).resume()
    }
    
    
    //MARK: Networking - JSON generation
    
    func generateJSON(dict: [String: Any]) ->Data?{
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            //print(String(data: jsonData, encoding: .utf8)!)
            
            return jsonData
        }catch{
            print(error)
            return nil
        }
    }
    
    func getAlertAsDictionary(alert: Alert) -> [String: Any]{
        var alertDays = [String: Bool]()
        
        if(alert.repeating){
            alertDays["mon"] = alert.days?[0]
            alertDays["tue"] = alert.days?[1]
            alertDays["wed"] = alert.days?[2]
            alertDays["thu"] = alert.days?[3]
            alertDays["fri"] = alert.days?[4]
            alertDays["sat"] = alert.days?[5]
            alertDays["sun"] = alert.days?[6]
        }else{
            alertDays["mon"] = false
            alertDays["tue"] = false
            alertDays["wed"] = false
            alertDays["thu"] = false
            alertDays["fri"] = false
            alertDays["sat"] = false
            alertDays["sun"] = false
        }
        let alertDateString = Alert.dateToString(date: alert.time as! Date)
        
        let dictionary: [String: Any] = ["time":alertDateString,"title":alert.title ?? " ","days":alertDays,"repeating":alert.repeating,"isEnabled":alert.isEnabled,"id":alert.id ?? ""]
        
        return dictionary
    }
    
    func getSettingsAsDictionary() -> [String: Any]{
        let settings = self.getSettings()
            
        let dictionary: [String: Any] = ["alertSound":settings.alertSound!,"hourMode":settings.hourMode!,"snoozeOn":settings.snoozeOn,"snoozeLength":settings.snoozeLength,"snoozeAmount":settings.snoozeAmount,"soundVolume":settings.soundVolume,"automaticSync":settings.automaticSync,"dateFormat":settings.dateFormat]
        
        return dictionary
    }
    
    //MARK: Networking: Generating dictionaries from JSON
    
    func getDictionaryFromJSON(data: Data?) -> [Any]?{
        do{
            let json = try JSONSerialization.jsonObject(with: data!, options:[]) as? [Any]
            return json
        
        }catch{
            print(error)
            return nil
        }
    }
    
}

