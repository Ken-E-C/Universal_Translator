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

struct ietfLanguageTag {
    var languageTag: String?
    var countryTag: String?
}


class LanguageManager: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = LanguageManager()
    
    var locationMgr = CLLocationManager()
    var detectedLangTag = ietfLanguageTag()
    
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
        
        
        checkPermissions()
        //then obtain location
        locationMgr.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //then reverse geocode location to get country code
        let geocoder = CLGeocoder()
        let ietfParser = LanguageParser()
        if let currentLocation = locations.last{
            geocoder.reverseGeocodeLocation(currentLocation) { (results, error) in
                let countryCode = results?.first?.isoCountryCode
                
                //go find the language code
                
            }
        }
    }
}
