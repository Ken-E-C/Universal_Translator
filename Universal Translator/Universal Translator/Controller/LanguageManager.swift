//
//  LanguageManager.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/14/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation



protocol LanguageManagerDelegate {
    func languageTagsUpdated()
}

class LanguageManager: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = LanguageManager()
    
    var locationMgr = CLLocationManager()
    var detectedLangTags = [bcp47LanguageTag]()
    //var allLanguageTags = [bcp47LanguageTag]()
    var selectedLocalLang = bcp47LanguageTag()
    var selectedTargetLang = bcp47LanguageTag()
    var TCViewController: TranslationCenterViewController?
    var isSearching = false
    
    override init() {
        super.init()
        locationMgr.delegate = self
        let localLang = Locale.current.languageCode ?? "en"
        let localCountry = Locale.current.regionCode?.uppercased() ?? "US"
        selectedTargetLang = LanguageParser.sharedInstance.findLanguageTagByCountryAndLanguageCode(languageCode: localLang, countryCode: localCountry)!
    }
    func checkPermissions() -> Bool{
        let status = CLLocationManager.authorizationStatus()
        switch status {
        // 1
        case .notDetermined:
            locationMgr.requestWhenInUseAuthorization()
            return true
        // 2
        case .denied, .restricted:

            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            print("Unknown case")
            return false
        }
    }
    
    func inferLanguage(){
        _ = checkPermissions()
        //then obtain location
        isSearching = true
        locationMgr.startUpdatingLocation()
    }
    
    func updateDetectedLanguages(languageCode: String){
        detectedLangTags = LanguageParser.sharedInstance.findRegionalDialects(detectedLanguage: languageCode)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //then reverse geocode location to get country code
        let geocoder = CLGeocoder()
        if let currentLocation = locations.last{
            //go find the language code
            locationMgr.stopUpdatingLocation()
            geocoder.reverseGeocodeLocation(currentLocation) { (results, error) in
                if let countryCode = results?.first?.isoCountryCode {
                    if self.isSearching{
                        self.isSearching = false
                        self.detectedLangTags = LanguageParser.sharedInstance.findSupportedLocalLanguages(countryCode: countryCode)
                        self.selectedLocalLang = self.detectedLangTags[0]
                        self.TCViewController?.languageTagsUpdated()
                    }
                }
            }
        }
    }
}
