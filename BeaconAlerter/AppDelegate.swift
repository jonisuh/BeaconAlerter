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
            let settings = Settings.createSettings(hourMode: "24", dateFormat: "dd MMM yyyy", snoozeOn: true, snoozeLength: 5, snoozeAmount: 1, alertSound: "Default", soundVolume: 1.0, automaticSync: true, context: self.container.viewContext)
            print("Settings initialized")
            
            try self.container.viewContext.save()
        }catch{
            print(error)
        }
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
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
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
            print("adding")
            print(notificationTrigger.nextTriggerDate() ?? "Trigger date not found")
            let content = UNMutableNotificationContent()
            content.title = alert.title!
            content.body = "Alert triggered."
            content.sound = UNNotificationSound.default()
            
            var request = UNNotificationRequest(identifier: id, content: content, trigger: notificationTrigger)
            
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
                    newComponents.weekday = i+2
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
        do{
            let alertRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alert")
            let alerts = try self.container.viewContext.fetch(alertRequest) as! [Alert]
            
            for alert in alerts{
                rescheduleNotification(alert: alert)
            }
            
        }catch{
            print(error)
        }
    }
}

