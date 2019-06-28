//
//  BoseWearableDeviceManager.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/18/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import BoseWearable
import UIKit

protocol BoseWearableDeviceManagerDelegate {
    func headNodDetected()
}

class BoseWearableDeviceManager: WearableDeviceSessionDelegate {
    
    static let sharedInstance = BoseWearableDeviceManager()
    
    var activeWearableSession: WearableDeviceSession!
    var device: WearableDevice!
    
    var delegate: TranslationCenterViewController?
    
    private var token: ListenerToken?
    
    var sensorDispatch = SensorDispatch(queue: .main)
    
    //MARK: Initial Configuration Stuff
    
    init() {
        startConfiguration()
    }
    func startConfiguration() {
        BoseWearable.configure()
        BoseWearable.enableCommonLogging()
        
        sensorDispatch.gestureDataCallback = { [weak self] gesture, timestamp in
            switch gesture {
            case .headNod:
                self?.delegate?.headNodDetected()
            case .headShake:
                self?.delegate?.headShakeDetected()
            default:
                return
            }
            guard case .headNod = gesture else {
                return
            }
            
        }
    }
    
    func searchForDevice() {
        BoseWearable.shared.startDeviceSearch(mode: .alwaysShowUI) { (result) in
            switch result {
            case .success(let session):
                // A device was selected. The session encapsulates communications with
                // the selected device.
                
                // Retain the session.
                self.activeWearableSession = session
                
                
                // Become the session's delegate to receive connectivity events.
                self.activeWearableSession!.delegate = self as WearableDeviceSessionDelegate
                
                // Open the session.
                self.activeWearableSession!.open()
                
                
            case .failure(let error):
                // An error occurred while performing the device search. Show the error
                // to the user.
                print("Error with connecting to Bose AR Device\(error)")
                
            case .cancelled:
                // The user cancelled the search.
                break
            }
        }
    }
    
    
    
    
    //MARK: Bose Wearable Connection Events
    func sessionDidOpen(_ session: WearableDeviceSession) {
        print("Session opened")
        device = activeWearableSession.device
        listenForWearableDeviceEvents()
        setupGestures()
        
    }

    func session(_ session: WearableDeviceSession, didFailToOpenWithError error: Error?) {
        print("Session failed with error \(String(describing: error))")
    }

    func session(_ session: WearableDeviceSession, didCloseWithError error: Error?) {
        print("Session closed with error \(String(describing: error))")
    }
    
    private func listenForWearableDeviceEvents() {
        token = activeWearableSession.device?.addEventListener(queue: .main) { [weak self] event in
            self?.wearableDeviceEvent(event)
        }
    }
    private func setupGestures() {
        activeWearableSession.device?.configureSensors { config in
            config.disableAll()
        }
        
        activeWearableSession.device?.configureGestures({ (config) in
            config.disableAll()
            config.set(gesture: .headNod, enabled: true)
            config.set(gesture: .headShake, enabled: true)
            
        })
    }

    
    private func wearableDeviceEvent(_ event: WearableDeviceEvent) {
        switch event {
        case .didFailToWriteSensorConfiguration(let error):
            // Show an error if we were unable to set the sensor configuration.
            print(error)
            
//        case .didSuspendWearableSensorService:
//            // Block the UI when the sensor service is suspended.
//            suspensionOverlay = SuspensionOverlay.add(to: navigationController?.view)
            
        case .didResumeWearableSensorService:
            // Unblock the UI when the sensor service is resumed.
            //suspensionOverlay?.removeFromSuperview()
            print("Resume Wearable Sensor Service")
        case .didReceiveGestureData(let gestureData):
            switch gestureData.gesture {
            case .headNod:
                delegate?.headNodDetected()
            default :
                print("\(gestureData.gesture) detected")
            }
        case .didFailToWriteGestureConfiguration(let error):
            print(error)
        default:
            break
        }
    }

    
    
    
}
