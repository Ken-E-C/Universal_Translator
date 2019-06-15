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

struct bcp47LanguageTag {
    var languageTag: String?
    var countryTag: String?
    var bcp47Tag: String?
}

protocol LanguageManagerProtocol {
    func languageTagsUpdated()
}

class LanguageManager: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = LanguageManager()
    
    var locationMgr = CLLocationManager()
    var detectedLangTags = [bcp47LanguageTag]()
    var TCViewController: TranslationCenterViewController?
    
    
    override init() {
        super.init()
        locationMgr.delegate = self
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
                    self.detectedLangTags = LanguageParser.sharedInstance.findSupportedLocalLanguages(countryCode: countryCode)
                    
                    self.TCViewController?.languageTagsUpdated()
                }
            }
        }
    }
}
