//
//  SettingsPickerViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 19.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit

class SettingsPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    @IBOutlet weak var dateFormatPicker: UIPickerView!
    
    let dateFormatter = DateFormatter()
    var dateFormats: [String]?
    var separator: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.separator = "."
        generateDateFormats(separator: separator!)
        
        self.dateFormatPicker.delegate = self
        self.dateFormatPicker.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func generateDateFormats(separator: String){
        var dateFormatsEU = [String]()
        var dateFormatsUS = [String]()
        
        for i in 1...4{
            let months = String(repeating: "M", count: i)
            dateFormatsEU.append("dd"+separator+months+separator+"yyyy")
            dateFormatsUS.append(months+separator+"dd"+separator+"yyyy")
        }
        
        self.dateFormats = dateFormatsEU + dateFormatsUS
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return (dateFormats?.count)!
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        dateFormatter.dateFormat = dateFormats?[row]
        let date = dateFormatter.string(from: Date())

        return date
    }
    
    
    @IBAction func changeSeparatorType(_ sender: UIButton) {
        if let btnTitle = sender.title(for: .normal){
            switch btnTitle{
            case "Dot":
                generateDateFormats(separator: ".")
            case "Space":
                generateDateFormats(separator: " ")
            case "Slash":
                generateDateFormats(separator: "/")
            default:
                print(btnTitle)
            }
            self.dateFormatPicker.reloadAllComponents()
        }
    }
    
    @IBAction func dateFormatPickConfirmed(_ sender: Any) {
        let selectedRow = self.dateFormatPicker.selectedRow(inComponent: 0)
        let selectedDateFormat = dateFormats?[selectedRow]
        
        let parent = self.popoverPresentationController?.delegate as! SettingsTableViewController
        
        parent.settings?.dateFormat = selectedDateFormat
        parent.returnFromPopover()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
