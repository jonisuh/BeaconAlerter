//
//  AlertTableViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 11.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class AlertTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate {

    var fetchedResultsController: NSFetchedResultsController<Alert>!
    let context = (UIApplication.shared.delegate as! AppDelegate).container.viewContext
    
    @IBOutlet var alertTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpFetchedResultsController()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
            
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        
    }
    
    //Can be used to reload tableview from outside, e.g when settings change
    func loadList(){
        print("didChange")
        self.alertTableView.reloadData()
    }

    //MARK: Fetched Result Controller setup
    private func setUpFetchedResultsController() {
        let fetchRequest = NSFetchRequest<Alert>(entityName: "Alert")
        let primarySortDescriptor = NSSortDescriptor(key: "repeating", ascending: false)
        let secondarySortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
        
        
        self.fetchedResultsController = NSFetchedResultsController<Alert>(
            fetchRequest: fetchRequest,
            managedObjectContext: self.context,
            sectionNameKeyPath: "repeating",
            cacheName: nil
        )
        
        self.fetchedResultsController.delegate = self
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 1
        
        if((fetchedResultsController.fetchedObjects?.count)! == 0){
            let rect = CGRect(x: 0, y: 0, width: self.alertTableView.bounds.size.width, height: self.alertTableView.bounds.size.height)
            let noDataLabel: UILabel = UILabel(frame: rect)
            noDataLabel.text = "No alerts"
            noDataLabel.textColor = UIColor.blue
            noDataLabel.textAlignment = NSTextAlignment.center
            self.alertTableView.backgroundView = noDataLabel
        }else{
            self.alertTableView.backgroundView = nil
            sections = (fetchedResultsController.sections?.count)!
        }
        
        return sections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(fetchedResultsController.sections?.count == 0){
            return 0
        }else{
            return (fetchedResultsController.sections?[section].numberOfObjects)!
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(fetchedResultsController.sections?.count != 0){
            switch section{
            case 0:
                return "Repeating"
            case 1:
                return "One time"
            default:
                return " "
            }
        }else{
            return " "
        }
    }
    // Set the spacing between sections
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section{
        case 0:
            return 30.0
        case 1:
            return 10.0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "alertCell", for: indexPath) as! AlertTableViewCell
        let alert = fetchedResultsController.object(at: indexPath)
        
        if(alert.title == ""){
            cell.titleLabel.text = " "
        }else{
            cell.titleLabel.text = alert.title!
        }
        
        let dateFormatter = DateFormatter()
        var dateFormat = ""
        
        if((UIApplication.shared.delegate as! AppDelegate).getSettings().hourMode == "24"){
            dateFormat = "HH:mm"
            cell.timeLabel.font = UIFont.systemFont(ofSize: 26.0)
        }else{
            dateFormat = "hh:mm a"
            cell.timeLabel.font = UIFont.boldSystemFont(ofSize: 17.5)
        }
        dateFormatter.dateFormat = dateFormat
        
        let time = dateFormatter.string(from: alert.time! as Date)
        
        cell.timeLabel.text = time
        cell.toggleButton.isOn = alert.isEnabled
        
        if(alert.repeating){ //Repeating alert
            //Checking if all days are selected
            var everyDaySelected = true
            for day in (alert.days)!{
                if(!day){
                    everyDaySelected = false
                }
            }
            
            if(everyDaySelected){
                cell.stackView.isHidden = true
                cell.dayLabels[0].text = "Every day"
                cell.dayLabels[0].font = UIFont.boldSystemFont(ofSize: 12)
                cell.dayLabels[0].textColor = UIColor.blue
                
            } else {
                cell.stackView.isHidden = false
                cell.dayLabels[0].text = "MON"
                for i in 0...6{
                    let label = cell.dayLabels[i]
                    if((alert.days?[i])!){
                        label.font = UIFont.boldSystemFont(ofSize: 12)
                        label.textColor = UIColor.blue
                    }else{
                        label.font = UIFont.italicSystemFont(ofSize: 12)
                        label.textColor = UIColor.lightGray
                    }
                }
                cell.stackView.isHidden = false
            }
        } else { //One time alert
            cell.stackView.isHidden = true
            dateFormatter.dateFormat = (UIApplication.shared.delegate as! AppDelegate).getSettings().dateFormat
            let date = dateFormatter.string(from: alert.time! as Date)
            
            cell.dayLabels[0].text = date
            cell.dayLabels[0].font = UIFont.systemFont(ofSize: 12)
            cell.dayLabels[0].textColor = UIColor.black
        }
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.beginUpdates()
            let alertToDelete = fetchedResultsController.object(at: indexPath)
            /*print(alertToDelete.title!)
            self.context.delete(alertToDelete) */
            
            let section = indexPath.section
            
            print("delete")
            
            if(fetchedResultsController.sections?[section].numberOfObjects == 1 && fetchedResultsController.sections?.count != 1){
                print("deleting")
                var indexSet = NSIndexSet(index: section)
                self.context.delete(alertToDelete)
                print("deleting section")
                self.alertTableView.deleteSections(indexSet as IndexSet, with: UITableViewRowAnimation.fade)
            }else{
                self.context.delete(alertToDelete)
                self.alertTableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
            //Removing all notifications scheduled from this alert
            (UIApplication.shared.delegate as! AppDelegate).cancelNotification(alert: alertToDelete)
            
            //Delete the alert from the server is automatic sync is on
            if((UIApplication.shared.delegate as! AppDelegate).getSettings().automaticSync){
                (UIApplication.shared.delegate as! AppDelegate).deleteAlertFromServer(alert: alertToDelete)
                print("deleteTest1")
            }
            
            do {
                try self.context.save()
            } catch {
                print("Something went wrong with deletion")
            }
            tableView.endUpdates()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            
        }    
    }
 

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        print("test")
        if var alerts = self.fetchedResultsController.fetchedObjects {
            let alert = alerts[fromIndexPath.row] as Alert
            alerts.remove(at: fromIndexPath.row)
            alerts.insert(alert, at: to.row)
            
            do {
                try self.context.save()
            } catch {
                print("Something went wrong with moving")
            }
        }
    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    //MARK: FetchedResultsController
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        
        switch type {
        case NSFetchedResultsChangeType.insert:
            print("insert")
        case NSFetchedResultsChangeType.delete:
            print("delete")
        case NSFetchedResultsChangeType.update:
            print("update")
        case NSFetchedResultsChangeType.move:
            print("move")
            /*
            if let deleteIndexPath = indexPath {
                self.alertTableView.deleteRows(at: [deleteIndexPath], with: UITableViewRowAnimation.fade)
            }
            if let insertIndexPath = newIndexPath {
                self.alertTableView.insertRows(at: [insertIndexPath], with: UITableViewRowAnimation.fade)
            }
            */
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("didChange")
        self.alertTableView.reloadData()
    }
    
    // MARK: - Navigation

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         //segue for the popover configuration window
        
        switch segue.identifier!{
        case "showNewAlertCreation","showAlertEdit":
            if let controller = segue.destination as? NewAlertViewController {
                controller.popoverPresentationController!.delegate = self
                controller.popoverPresentationController!.sourceView = self.view
                controller.popoverPresentationController!.sourceRect = CGRect(x: self.view.bounds.midX-100, y: self.view.bounds.midY-50, width: 0, height: 0)
                controller.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                controller.preferredContentSize = CGSize(width: 600, height: 450)
                
                if(segue.identifier == "showAlertEdit"){
                    let path = self.alertTableView.indexPathForSelectedRow!
                    controller.alertToBeEdited = self.fetchedResultsController.object(at: path)
                }
                
            }
            
        case "showMoreActions":
            if let controller = segue.destination as? MoreActionsViewController {
                controller.popoverPresentationController!.delegate = self
                controller.preferredContentSize = CGSize(width: 200, height: 100)
            }
            
        default:
            print(segue.identifier!)
        }
     }
    
    //MARK: Popover
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        //Prevent dismissing of alert popover
        if((UIApplication.shared.delegate as! AppDelegate).lastPopover == "AlertPopupViewController"){
            return false
        }else{
            return true
        }
    }
    
    //MARK: Notifications
     
    
    
    //MARK: Misc action
    @IBAction func switchChanged(_ sender: UISwitch) {
        let location = sender.convert(CGPoint.zero, to: alertTableView)
        let alert = fetchedResultsController.object(at: alertTableView.indexPathForRow(at: location)!)
        alert.isEnabled = !alert.isEnabled
        
        do {
            try self.context.save()
        } catch {
            print("Something went wrong with deletion")
        }
        
        if(alert.isEnabled){
            (UIApplication.shared.delegate as! AppDelegate).scheduleNotification(alert: alert)
        }else{
            (UIApplication.shared.delegate as! AppDelegate).cancelNotification(alert: alert)
        }
        
        if((UIApplication.shared.delegate as! AppDelegate).getSettings().automaticSync){
            (UIApplication.shared.delegate as! AppDelegate).updateAlertInServer(alert: alert)
        }
    }
    
}
