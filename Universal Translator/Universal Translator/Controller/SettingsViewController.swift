//
//  SettingsViewController.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 7/10/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
   
    @IBOutlet weak var languageDetectEnableSwitch: UISwitch!
    
    @IBOutlet weak var bluetoothHeadsetEnableSwitch: UISwitch!
    @IBOutlet weak var captureSelector: UISegmentedControl!
    @IBOutlet weak var outputSelector: UISegmentedControl!
    
    
    @IBOutlet weak var gesturesEnableSwitch: UISwitch!
    @IBOutlet weak var detectLangTextSwitch: UISwitch!
    @IBOutlet weak var enableVoiceOutputSwitch: UISwitch!
    
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.rowHeight = UITableView.automaticDimension
        settingsTableView.estimatedRowHeight = 600
        
        let languageDetectionEnableValue: Bool = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .get, setting: .inferLanguage, to: nil) as? Bool ?? true
        
        let bluetoothHeadsetEnableValue: Bool = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .get, setting: .bluetoothHeadsetEnable, to: nil) as? Bool ?? true
        
        let gesturesEnableValue: Bool = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .get, setting: .gestureEnable, to: nil) as? Bool ?? true
        
        let detectLangTextValue: Bool = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .get, setting: .detectLocalLanguageText, to: nil) as? Bool ?? true
        
        let enableVoiceOutputValue: Bool = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .get, setting: .enableVoiceOutput, to: nil) as? Bool ?? true
        
        
        
        languageDetectEnableSwitch.setOn( languageDetectionEnableValue, animated: false)
        bluetoothHeadsetEnableSwitch.setOn(bluetoothHeadsetEnableValue, animated: false)
        gesturesEnableSwitch.setOn(gesturesEnableValue, animated: false)
        detectLangTextSwitch.setOn(detectLangTextValue, animated: false)
        enableVoiceOutputSwitch.setOn(enableVoiceOutputValue, animated: false)
        
    }
    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 5
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        switch indexPath.row {
//        case 0:
//            return settingsTableView.dequeueReusableCell(withIdentifier: "LanguageSettingCell", for: indexPath)
//        case 1:
//            return settingsTableView.dequeueReusableCell(withIdentifier: "BluetoothEnableCell", for: indexPath)
//        case 2:
//            return settingsTableView.dequeueReusableCell(withIdentifier: "GeatureEnableCell", for: indexPath)
//        case 3:
//            return settingsTableView.dequeueReusableCell(withIdentifier: "LanguageDetectEnableCell", for: indexPath)
//        case 4:
//            return settingsTableView.dequeueReusableCell(withIdentifier: "VoiceOutputEnableCell", for: indexPath)
//        default:
//            fatalError("unknown setting being loaded")
//        }
//    }

    @IBAction func inferLocalLanguageSwitchToggled(_ sender: Any) {
        let value = languageDetectEnableSwitch.isOn
        
        _ = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .set, setting: .inferLanguage, to: value)
        LanguageManager.sharedInstance.inferLanguage()
    }
    
    @IBAction func bluetoothHeadsetEnableSwitchToggled(_ sender: Any) {
        let value = bluetoothHeadsetEnableSwitch.isOn
        
        _ = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .set, setting: .bluetoothHeadsetEnable, to: value)
        
    }
    
    @IBAction func gesturesEnableSwitchToggled(_ sender: Any) {
        let value = gesturesEnableSwitch.isOn
        
        _ = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .set, setting: .gestureEnable, to: value)
        if value {
            BoseWearableDeviceManager.sharedInstance.searchForDevice()
        }
        else {
            BoseWearableDeviceManager.sharedInstance.closeSession()
        }
        
    }
    
    @IBAction func detectLangTextSwitchToggled(_ sender: Any) {
        let value = detectLangTextSwitch.isOn
        
        _ = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .set, setting: .detectLocalLanguageText, to: value)
    }
    
    @IBAction func voiceOutputSwitchToggled(_ sender: Any) {
        let value = enableVoiceOutputSwitch.isOn
        
        _ = GlobalSettingsManager.sharedInstance.setGet(setGetStatus: .set, setting: .enableVoiceOutput, to: value)
    }
    
    
    
    
    
}
