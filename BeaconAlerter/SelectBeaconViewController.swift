//
//  SelectBeaconViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 1.3.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import CoreBluetooth

class SelectBeaconViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource  {
    var manager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var beacons: [String: CBPeripheral]?
    var beaconNames: [String]?
    
    @IBOutlet weak var beaconTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("asd")
        
        self.beaconTableView.delegate = self
        self.beaconTableView.dataSource = self
        
        self.beacons = [String: CBPeripheral]()
        self.beaconNames = [String]()
        
        self.manager = CBCentralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.beaconNames?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "alertSoundCell", for: indexPath) as! SoundsTableViewCell
        
        // Configure the cell...
        cell.soundNameLabel.text = self.beaconNames?[indexPath.row]
        cell.soundNameLabel.textColor = UIColor.init(colorLiteralRed: 121/255, green: 143/255, blue: 255/255, alpha: 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = self.beaconNames?[indexPath.row]
        
        let beacon = self.beacons?[name!]
        
        print(beacon?.name)
        print(beacon?.readRSSI())
        print(beacon?.state)
        for service in (beacon?.services)!{
            print(service)
        }
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn{
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
       // peripheral.discoverServices(nil)
        
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String{
            //if(!(self.beaconNames?.contains(deviceName))!){
                print("______________________________")
                print(RSSI)
                for data in advertisementData{
                    print(data)
                }
                
                if let serviceuuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? NSArray{
                    print("serviceUUIDS")
                    for uuid in serviceuuids{
                        print(uuid)
                    }
                }
                
                if let servicedata = advertisementData[CBAdvertisementDataServiceDataKey] as? String{
                    print("servicedata")
                    print(servicedata)
                }
                
                print("______________________________")
                //self.manager.stopScan()
              //  self.beaconNames?.append(deviceName)
               // self.beacons?[deviceName] = peripheral
              //  self.beaconTableView.reloadData()
           // }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        manager.stopScan()
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
