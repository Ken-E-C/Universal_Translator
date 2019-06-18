//
//  VoiceInfoParser.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/16/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ssmlInfoTag {
    var language: String?
    var voiceType: String?
    var languageCode: String?
    var voiceName: String?
    var ssmlGender: String?
}

class VoiceInfoParser {
    static let sharedInstance = VoiceInfoParser()
    
    var voiceTags: JSON?
    var allVoiceTags = [ssmlInfoTag]()
    
    init() {
        if let path = Bundle.main.path(forResource: "supportedVoices", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                voiceTags = try JSON(data: data)
                loadAllVoiceFormats()
                
            } catch {
                fatalError("Error loading JSON file")
            }
        }
    }
    //MARK: Load available voices from JSON
    private func loadAllVoiceFormats() {
        guard let verifiedVoiceTags = voiceTags else {
            fatalError("Error parsing JSON file ")
        }
        
        
        var supportedVoiceTags = [ssmlInfoTag]()
        for index in 0...(verifiedVoiceTags.count - 1){
            
            var newTag = ssmlInfoTag()
            let voiceTag = verifiedVoiceTags[index]
            guard let language = voiceTag["Language"].string else {
                fatalError("error parsing language name")
            }
            newTag.language = language
            
            guard let voiceType = voiceTag["Voice type"].string else {
                fatalError("error parsing language name")
            }
            newTag.voiceType = voiceType
            
            guard let bcp47languageCode = voiceTag["Language code"].string else {
                fatalError("error parsing Language Code")
            }
            newTag.languageCode = bcp47languageCode
            
            guard let voiceName = voiceTag["Voice name"].string else {
                fatalError("error parsing language name")
            }
            newTag.voiceName = voiceName
            
            guard let ssmlGender = voiceTag["SSML Gender"].string else {
                fatalError("error parsing language name")
            }
            newTag.ssmlGender = ssmlGender
            
            
            supportedVoiceTags.append(newTag)
            
        }
        allVoiceTags = supportedVoiceTags
    
    }
    
    func getVoiceTagByLanguageCode(languageCode: String) -> ssmlInfoTag? {
        for voiceTag in allVoiceTags {
            if let verifiedVoiceTagLanguageCode = voiceTag.languageCode {
                if verifiedVoiceTagLanguageCode == languageCode{
                    return voiceTag
                }
            }
        }
        return nil
    }
    
    func getAvailableRegionalVoices(languageCode: String) -> [ssmlInfoTag] {
        
        var regionalVoices = [ssmlInfoTag]()
        for voiceTag in allVoiceTags {
            if let verifiedVoiceTagLanguageCode = voiceTag.languageCode {
                if verifiedVoiceTagLanguageCode == languageCode{
                     regionalVoices.append(voiceTag)
                }
            }
        }
        return regionalVoices
    }
    
    func getAvailableRegionalVoicesbyISOlangCode(isoLanguageCode: String) -> [ssmlInfoTag] {
        var regionalVoices = [ssmlInfoTag]()
        for voiceTag in allVoiceTags {
            if let verifiedVoiceTagLanguageCode = voiceTag.languageCode {
                if "\(verifiedVoiceTagLanguageCode.prefix(2))" == isoLanguageCode{
                    regionalVoices.append(voiceTag)
                }
            }
        }
        return regionalVoices
    }
    
}
