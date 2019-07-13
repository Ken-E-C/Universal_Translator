//
//  GlobalSettingsManager.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 7/9/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation

enum SetGetType {
    case set
    case get
}

enum SettingsType {
    case inferLanguage
    case bluetoothHeadsetEnable
    case bluetoothInputEnable
    case bluetoothOutputEnable
    case gestureEnable
    case detectLocalLanguageText
    case enableVoiceOutput
}


class GlobalSettingsManager {
    
    //pull data from User Defaults
    
    static let sharedInstance = GlobalSettingsManager()
    
    
    func getSettings() {
        
    }
    
    func setGet(setGetStatus: SetGetType, setting: SettingsType, to value: Any?) -> Any?{
        
        switch setGetStatus {
            
        case .set:
            UserDefaults.standard.set(value, forKey: "\(setting)")
        case .get:
            return UserDefaults.standard.bool(forKey: "\(setting)")
        }
        return nil
    }
    
    func saveSettings() {
        
    }
    
    
    
    
    
    
    
}
