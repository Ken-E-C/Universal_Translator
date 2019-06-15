//
//  ietfParser.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/14/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import SwiftyJSON
class LanguageParser {
    
    static let sharedInstance = LanguageParser()
    var languageTags: JSON?
    
    init() {
        if let path = Bundle.main.path(forResource: "language-tags", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                languageTags = try JSON(data: data)
                
            } catch {
                fatalError("Error loading  JSON file")
            }
        }
    }
    
    func findSupportedLocalLanguages(countryCode: String) -> [bcp47LanguageTag]{
        
        guard let verifiedLanguageTags = languageTags else {
            fatalError("Error parsing JSON file ")
        }
        
        var supportedLanguageTags = [bcp47LanguageTag]()
        for index in 0...(verifiedLanguageTags.count - 1){
            
            let languageTag = verifiedLanguageTags[index]
            guard let bcp47languageCode = languageTag["languageCode"].string else {
                fatalError("error parsing language code")
            }
            
            //Madarin doesn't have a country code associated with it for some reason. So I added an exception since this is the only time this happens
            if bcp47languageCode.contains("-\(countryCode)") || countryCode == "CN"{
                //build a language tag
                var newTag = bcp47LanguageTag()
                newTag.countryTag = countryCode
                newTag.bcp47Tag = bcp47languageCode
                //added in exception for Hong Kong Cantonese
                newTag.languageTag = bcp47languageCode == "yue-Hant-HK" ? String(bcp47languageCode.prefix(3)): String(bcp47languageCode.prefix(2))
                
                supportedLanguageTags.append(newTag)
            }
        }
        return supportedLanguageTags
    }
    
    func findRegionalDialects(detectedLanguage: String) -> [bcp47LanguageTag] {
        guard let verifiedLanguageTags = languageTags else {
            fatalError("Error parsing JSON file ")
        }
        
        var supportedLanguageTags = [bcp47LanguageTag]()
        for index in 0...(verifiedLanguageTags.count - 1){
            
            let languageTag = verifiedLanguageTags[index]
            guard let bcp47languageCode = languageTag["languageCode"].string else {
                fatalError("error parsing language code")
            }
            
            //cantonese has a 3 letter language code for some reason so adding an exception here
            if bcp47languageCode.contains("\(detectedLanguage)"){
                //build a language tag
                var newTag = bcp47LanguageTag()
                newTag.countryTag =  String(bcp47languageCode.suffix(2))
                newTag.bcp47Tag = bcp47languageCode
                //added in exception for Hong Kong Cantonese
                newTag.languageTag = bcp47languageCode == "yue-Hant-HK" ? String(bcp47languageCode.prefix(3)): String(bcp47languageCode.prefix(2))
                
                supportedLanguageTags.append(newTag)
            }
        }
        return supportedLanguageTags
    }
    
    
    
}
