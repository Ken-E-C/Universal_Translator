//
//  ietfParser.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/14/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import SwiftyJSON


struct bcp47LanguageTag {
    var languageName: String?
    var languageTag: String?
    var countryTag: String?
    var bcp47Tag: String?
}

class LanguageParser {
    
    static let sharedInstance = LanguageParser()
    var languageTags: JSON?
    var allLanguageTags = [bcp47LanguageTag]()

    
    init() {
        if let path = Bundle.main.path(forResource: "language-tags", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                languageTags = try JSON(data: data)
                loadAllLanguages()
                
            } catch {
                fatalError("Error loading  JSON file")
            }
        }
    }
    func findLanguageTag(languageCode: String) -> bcp47LanguageTag?{
        for languageTag in allLanguageTags {
            if languageTag.languageTag == languageCode {
                return languageTag
            }
        }
        return nil
    }
    
    func findLanguageTagByCountryCode(countryCode: String) -> bcp47LanguageTag?{
        for languageTag in allLanguageTags {
            if languageTag.countryTag == countryCode {
                return languageTag
            }
        }
        return nil
    }
    
    func findLanguageTagByCountryAndLanguageCode(languageCode: String, countryCode: String) -> bcp47LanguageTag?{
        for languageTag in allLanguageTags {
            if languageTag.countryTag == countryCode && languageTag.languageTag == languageCode{
                return languageTag
            }
        }
        return nil
    }
    func getLanguageTags() -> [bcp47LanguageTag] {
        return allLanguageTags
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
            
            guard let languageName = languageTag["Language (English name)"].string else {
                fatalError("error parsing language name")
            }
            //Madarin doesn't have a country code associated with it for some reason. So I added an exception since this is the only time this happens
            if bcp47languageCode.contains("-\(countryCode)") || countryCode == "CN"{
                //build a language tag
                var newTag = bcp47LanguageTag()
                newTag.languageName = languageName
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
            guard let languageName = languageTag["Language (English name)"].string else {
                fatalError("error parsing language name")
            }
            
            //cantonese has a 3 letter language code for some reason so adding an exception here
            if bcp47languageCode.contains("\(detectedLanguage)"){
                //build a language tag
                var newTag = bcp47LanguageTag()
                newTag.countryTag =  String(bcp47languageCode.suffix(2))
                newTag.languageName = languageName
                newTag.bcp47Tag = bcp47languageCode
                //added in exception for Hong Kong Cantonese
                newTag.languageTag = bcp47languageCode == "yue-Hant-HK" ? String(bcp47languageCode.prefix(3)): String(bcp47languageCode.prefix(2))
                
                supportedLanguageTags.append(newTag)
            }
        }
        return supportedLanguageTags
    }
    
    private func loadAllLanguages() {
        guard let verifiedLanguageTags = languageTags else {
            fatalError("Error parsing JSON file ")
        }
        
        
        var supportedLanguageTags = [bcp47LanguageTag]()
        for index in 0...(verifiedLanguageTags.count - 1){
            
            let languageTag = verifiedLanguageTags[index]
            guard let bcp47languageCode = languageTag["languageCode"].string else {
                fatalError("error parsing language code")
            }
            guard let languageName = languageTag["Language (English name)"].string else {
                fatalError("error parsing language name")
            }
            
            
            //build a language tag
            var newTag = bcp47LanguageTag()
            newTag.countryTag = "\(bcp47languageCode.suffix(2))"
            newTag.languageName = languageName
            newTag.bcp47Tag = bcp47languageCode
            //added in exception for Hong Kong Cantonese
            newTag.languageTag = bcp47languageCode == "yue-Hant-HK" ? String(bcp47languageCode.prefix(3)): String(bcp47languageCode.prefix(2))
            
            supportedLanguageTags.append(newTag)
            
        }
        allLanguageTags = supportedLanguageTags
    }
    
    
    
}
