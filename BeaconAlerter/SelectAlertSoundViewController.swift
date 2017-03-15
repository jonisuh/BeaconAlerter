//
//  SelectAlertSoundViewController.swift
//  BeaconAlerter
//
//  Created by iosdev on 20.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import UIKit
import AVFoundation

class SelectAlertSoundViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var alertSoundsTableView: UITableView!
    var bundle: Bundle?
    var sounds: [String]?
    
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.alertSoundsTableView.delegate = self
        self.alertSoundsTableView.dataSource = self
        self.alertSoundsTableView.frame.size.width = preferredContentSize.width*0.90
        
        // Do any additional setup after loading the view.
        
        self.bundle = Bundle.main
        
        let enumerator = FileManager.default.enumerator(atPath: (self.bundle?.bundlePath)!)
        self.sounds = [String]()
        while let element = enumerator?.nextObject() as? String {
            if (element.hasSuffix(".wav")) {
                self.sounds?.append(element.components(separatedBy: ".")[0])
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.sounds?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "alertSoundCell", for: indexPath) as! SoundsTableViewCell
        
        // Configure the cell...
        cell.soundNameLabel.text = self.sounds?[indexPath.row]
        cell.soundNameLabel.textColor = UIColor.init(colorLiteralRed: 121/255, green: 143/255, blue: 255/255, alpha: 1)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopSound()
        print(self.sounds?[indexPath.row])
        playSound(sound: (self.sounds?[indexPath.row])!)
    }
    
    func playSound(sound: String) {
        let url = bundle?.url(forResource: sound, withExtension: "wav")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url!)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
            player.volume = Float((UIApplication.shared.delegate as! AppDelegate).getSettings().soundVolume)
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
    
    @IBAction func selectAlertSound(_ sender: Any) {

        if let selectedRow = self.alertSoundsTableView.indexPathForSelectedRow{
        let selectedSound = self.sounds?[selectedRow.row]
            
            let parent = self.popoverPresentationController?.delegate as! SettingsTableViewController
            
            parent.settings?.alertSound = selectedSound
            parent.returnFromPopover()
            
            (UIApplication.shared.delegate as! AppDelegate).rescheduleAllNotifications()
            self.dismiss(animated: true, completion: nil)
        }
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
