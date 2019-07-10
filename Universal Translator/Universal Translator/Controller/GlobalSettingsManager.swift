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
    case bluetoothEnable
    case bluetoothInputEnable
    case bluetoothOutputEnable
    case detectLocalLanguageText
    case enableVoiceOutput
    
    
}


class GlobalSettingsManager {
    
    //pull data from User Defaults
    
    static let sharedInstance = GlobalSettingsManager()
    init() {
        loadSettings()
    }
    
    private func loadSettings(){
        
    }
    
    func setGet(setGetStatus: SetGetType, setting: SettingsType, to value: Bool){
        
    }
    
    func saveSettings() {
        
    }
    
    
    
    
    
    
    
}
