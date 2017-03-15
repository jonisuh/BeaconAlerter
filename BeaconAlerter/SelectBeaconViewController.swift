//
//  SelectBeaconViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 1.3.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreBluetooth

class SelectBeaconViewController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource  {
    var manager: CBCentralManager!
    
    @IBOutlet weak var startScanButton: UIButton!
    @IBOutlet weak var beaconTableView: UITableView!
    @IBOutlet weak var scanIndicator: UIActivityIndicatorView!
    
    var beacons: [String: BeaconInfo]?
    var beaconIDs: [String]?
    
    var isScanning: Bool!
    var stopScanningTask: DispatchWorkItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.beaconTableView.delegate = self
        self.beaconTableView.dataSource = self
        
        //self.beaconTableView.frame.size.width = preferredContentSize.width*0.90
        
        self.beacons = [String: BeaconInfo]()
        self.beaconIDs = [String]()
        
        self.manager = CBCentralManager(delegate: self, queue: nil)
        
        self.startScanButton.isEnabled = false
        self.isScanning = false
        self.scanIndicator.isHidden = true
        
        self.stopScanningTask = DispatchWorkItem{
            print("Stopping scan")
            self.startScanButton.setTitle("Scan", for: .normal)
            self.manager.stopScan()
            self.scanIndicator.isHidden = true
            self.isScanning = false
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        let sections = 1
        
        if(beaconIDs?.count == 0){
            let rect = CGRect(x: 0, y: 0, width: self.beaconTableView.bounds.size.width, height: self.beaconTableView.bounds.size.height)
            let noDataLabel: UILabel = UILabel(frame: rect)
            noDataLabel.text = "No beacons found"
            noDataLabel.textColor = UIColor.blue
            noDataLabel.textAlignment = NSTextAlignment.center
            self.beaconTableView.backgroundView = noDataLabel
        }else{
            self.beaconTableView.backgroundView = nil
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.beaconIDs?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell", for: indexPath) as! BeaconTableViewCell
        // Configure the cell...
        let beaconName = self.beaconIDs?[indexPath.row]
        let beaconInfo = self.beacons?[beaconName!]
        
        cell.beaconIDLabel.text = beaconName
        
        cell.beaconIDLabel.textColor = UIColor.init(colorLiteralRed: 121/255, green: 143/255, blue: 255/255, alpha: 1)
        
        let range = "\(beaconInfo?.RSSI ?? 0)"
      
        cell.rangeLabel.text = range
        
        cell.deviceNameLabel.text = beaconInfo?.deviceName
        cell.deviceNameLabel.textColor = UIColor.init(colorLiteralRed: 121/255, green: 143/255, blue: 255/255, alpha: 1)
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(isScanning == true){
            //Stops scanning -> updating table view, if user selects a row
            startScan(sender: startScanButton)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn{
            startScanButton.isEnabled = true
        } else {
            print("Bluetooth not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        

        if let servicedata = advertisementData[CBAdvertisementDataServiceDataKey] as? [NSObject: AnyObject]{
            var eft: BeaconInfo.EddystoneFrameType
            eft = BeaconInfo.frameTypeForFrame(advertisementFrameList: servicedata)
            
            print(RSSI)
            if eft == BeaconInfo.EddystoneFrameType.UIDFrameType {
                let telemetry = NSData()
                let serviceUUID = CBUUID(string: "FEAA")
                let _RSSI: Int = RSSI.intValue
                let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
                
                
                if let beaconServiceData = servicedata[serviceUUID] as? NSData, let beaconInfo = BeaconInfo.beaconInfoForUIDFrameData(frameData: beaconServiceData, telemetry: telemetry, RSSI: _RSSI, deviceName: deviceName){
                    let beaconID = BeaconInfo.hexaDecimalString(from: beaconInfo.beaconID.beaconID)
                    print(beaconID)
                    
                    if(!(self.beaconIDs?.contains(beaconID))!){
                        self.beaconIDs?.append(beaconID)
                        self.beacons?[beaconID] = beaconInfo
                        self.beaconTableView.reloadData()
                    }else{
                        self.beacons?[beaconID] = beaconInfo
                        self.beaconTableView.reloadData()
                        print("Reloading")
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
    
    
    @IBAction func cancel(_ sender: Any) {
        self.manager.stopScan()
        self.stopScanningTask.cancel()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func startScan(_ sender: Any) {
        if(!self.isScanning){
            self.startScanButton.setTitle("Stop", for: .normal)
            self.manager.scanForPeripherals(withServices: nil, options: nil)
            self.scanIndicator.startAnimating()
            self.scanIndicator.isHidden = false
            
            self.beaconIDs = [String]()
            self.beacons = [String: BeaconInfo]()
            self.beaconTableView.reloadData()
            
            self.isScanning = true
            self.stopScanningTask.cancel()
            self.stopScanningTask = DispatchWorkItem{
                print("Stopping scan")
                self.startScanButton.setTitle("Scan", for: .normal)
                self.manager.stopScan()
                self.scanIndicator.isHidden = true
                self.isScanning = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30), execute: stopScanningTask)
        
            
        }else{
            self.startScanButton.setTitle("Scan", for: .normal)
            self.manager.stopScan()
            self.scanIndicator.isHidden = true
            self.isScanning = false
            
            self.stopScanningTask.cancel()
        }
    }
    
    @IBAction func selectBeacon(_ sender: Any) {
        if let selectedRow = self.beaconTableView.indexPathForSelectedRow{
            let selectedBeaconID = self.beaconIDs?[selectedRow.row]
            
            let parent = self.popoverPresentationController?.delegate as! SettingsTableViewController
            
            parent.settings?.beaconID = selectedBeaconID
            parent.returnFromPopover()
            self.manager.stopScan()
            self.stopScanningTask.cancel()
            self.dismiss(animated: true, completion: nil)
        }
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
