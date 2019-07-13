//
//  VoiceManager.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/16/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftyJSON

enum VoiceError: Error {
    case invalidData
}

class VoiceManager: NSObject, AVAudioPlayerDelegate {
    
    static let sharedInstance = VoiceManager()
    let ttsAPIUrl = "https://texttospeech.googleapis.com/v1beta1/text:synthesize"
    private(set) var busy: Bool = false
    
    private var player: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    
    var selectedVoice: ssmlInfoTag?
    var availableRegionalVoices = [ssmlInfoTag]()
    
    var timeoutTimer: Timer?
    var timeoutCallback: ((String)->(Void))?
    var isRunning = false
    
    func setVoiceTag(languageCode: String) {
        selectedVoice = VoiceInfoParser.sharedInstance.getVoiceTagByLanguageCode(languageCode: languageCode)
    }
    func setRegionalTags(languageCode: String) {
        availableRegionalVoices = VoiceInfoParser.sharedInstance.getAvailableRegionalVoices(languageCode: languageCode)
        
    }
    func getRegionalTags() -> [ssmlInfoTag]{
        return availableRegionalVoices
    }
    func setEquivalentRegionalTags(isoLanguageCode: String) {
        availableRegionalVoices = VoiceInfoParser.sharedInstance.getAvailableRegionalVoicesbyISOlangCode(isoLanguageCode: isoLanguageCode)
    }
    
    func speak(text: String, completion: @escaping () -> Void) {
        isRunning = true
        guard let verifiedSelectedVoice = selectedVoice else {
            return
        }
        let voiceType = verifiedSelectedVoice.voiceType
        guard !self.busy else {
            print("Speech Service busy!")
            return
        }

        self.busy = true
        self.resetTimeoutTimer()
        DispatchQueue.global(qos: .background).async {
            guard let postData = self.buildPostData(text: text) else {return}
            let headers = ["X-Goog-Api-Key": googleCloudAPIKey, "Content-Type": "application/json; charset=utf-8"]
            
            let response = self.makePOSTRequest(url: self.ttsAPIUrl, postData: postData, headers: headers)
            self.timeoutTimer?.invalidate()
            
            if !self.isRunning {
                return
            }
            self.isRunning = false
            // Get the `audioContent` (as a base64 encoded string) from the response.
            guard let audioContent = response["audioContent"] as? String else {
                print("Invalid response: \(response)")
                self.busy = false
                DispatchQueue.main.async {
                    completion()
                }
                return
            }

            // Decode the base64 string into a Data object
            guard let audioData = Data(base64Encoded: audioContent) else {
                self.busy = false
                DispatchQueue.main.async {
                    completion()
                }
                return
            }

            DispatchQueue.main.async {
                self.completionHandler = completion
                self.player = try! AVAudioPlayer(data: audioData)
                self.player?.delegate = self
                self.player?.prepareToPlay()
                self.player!.play()
            }
        }
    }
    
        private func buildPostData(text: String) -> Data? {
            guard let verifiedSelectedVoice = selectedVoice else {
                return nil
            }
            let voiceType = verifiedSelectedVoice.voiceName
            var voiceParams: [String: Any] = [
                // All available voices here: https://cloud.google.com/text-to-speech/docs/voices
                "languageCode": verifiedSelectedVoice.languageCode!
            ]
            voiceParams["name"] = voiceType

    
            let params: [String: Any] = [
                "input": [
                    "text": text
                ],
                "voice": voiceParams,
                "audioConfig": [
                    // All available formats here: https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#audioencoding
                    "audioEncoding": "LINEAR16"
                ]
            ]
    
            // Convert the Dictionary to Data
            let data = try! JSONSerialization.data(withJSONObject: params)
            return data
        }
    
    
    
     //Just a function that makes a POST request.
    private func makePOSTRequest(url: String, postData: Data, headers: [String: String] = [:]) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = postData

        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        // Using semaphore to make request synchronous
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
                dict = json
            }
            


            semaphore.signal()
        }

        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        return dict
    }
    
    // Implement AVAudioPlayerDelegate "did finish" callback to cleanup and notify listener of completion.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player?.delegate = nil
        self.player = nil
        self.busy = false
        
        self.completionHandler!()
        self.completionHandler = nil
    }
    
    private func resetTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timeoutTimerFired), userInfo: nil, repeats: false)
    }
    
    @objc private func timeoutTimerFired() {
        isRunning = false
        //notify TranslationCenter that the Voice Manager Timed Out
        guard let verifiedTimeoutCallback = timeoutCallback else {
            fatalError("No timeout callback was initialized in the VoiceManager")
        }
        verifiedTimeoutCallback("Text to Speech Timed Out")
    }
}
