//
//  VoiceManager.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/16/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import AVFoundation

class VoiceManager {
    
    static let sharedInstance = VoiceManager()
    
    private(set) var busy: Bool = false
    
    private var player: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    
    var selectedVoice: ssmlInfoTag?
    var availableRegionalVoices = [ssmlInfoTag]()
    
//    func speak(text: String, voiceType: VoiceType = .waveNetFemale, completion: @escaping () -> Void) {
//        guard !self.busy else {
//            print("Speech Service busy!")
//            return
//        }
//
//        self.busy = true
//
//        DispatchQueue.global(qos: .background).async {
//            let postData = self.buildPostData(text: text, voiceType: voiceType)
//            let headers = ["X-Goog-Api-Key": APIKey, "Content-Type": "application/json; charset=utf-8"]
//            let response = self.makePOSTRequest(url: ttsAPIUrl, postData: postData, headers: headers)
//
//            // Get the `audioContent` (as a base64 encoded string) from the response.
//            guard let audioContent = response["audioContent"] as? String else {
//                print("Invalid response: \(response)")
//                self.busy = false
//                DispatchQueue.main.async {
//                    completion()
//                }
//                return
//            }
//
//            // Decode the base64 string into a Data object
//            guard let audioData = Data(base64Encoded: audioContent) else {
//                self.busy = false
//                DispatchQueue.main.async {
//                    completion()
//                }
//                return
//            }
//
//            DispatchQueue.main.async {
//                self.completionHandler = completion
//                self.player = try! AVAudioPlayer(data: audioData)
//                self.player?.delegate = self
//                self.player!.play()
//            }
//        }
//    }
    
    //    private func buildPostData(text: String, voiceType: VoiceType) -> Data {
    //
    //        var voiceParams: [String: Any] = [
    //            // All available voices here: https://cloud.google.com/text-to-speech/docs/voices
    //            "languageCode": "en-US"
    //        ]
    //
    //        if voiceType != .undefined {
    //            voiceParams["name"] = voiceType.rawValue
    //        }
    //
    //        let params: [String: Any] = [
    //            "input": [
    //                "text": text
    //            ],
    //            "voice": voiceParams,
    //            "audioConfig": [
    //                // All available formats here: https://cloud.google.com/text-to-speech/docs/reference/rest/v1beta1/text/synthesize#audioencoding
    //                "audioEncoding": "LINEAR16"
    //            ]
    //        ]
    //
    //        // Convert the Dictionary to Data
    //        let data = try! JSONSerialization.data(withJSONObject: params)
    //        return data
    //    }
    
    func setVoiceTag(languageCode: String) {
        selectedVoice = VoiceInfoParser.sharedInstance.getVoiceTagByLanguageCode(languageCode: languageCode)
    }
    func setRegionalTags(languageCode: String) {
        availableRegionalVoices = VoiceInfoParser.sharedInstance.getAvailableRegionalVoices(languageCode: languageCode)
    }
    func getRegionalTags() -> [ssmlInfoTag]{
        return availableRegionalVoices
    }
    
    // Just a function that makes a POST request.
//    private func makePOSTRequest(url: String, postData: Data, headers: [String: String] = [:]) -> [String: AnyObject] {
//        var dict: [String: AnyObject] = [:]
//
//        var request = URLRequest(url: URL(string: url)!)
//        request.httpMethod = "POST"
//        request.httpBody = postData
//
//        for header in headers {
//            request.addValue(header.value, forHTTPHeaderField: header.key)
//        }
//
//        // Using semaphore to make request synchronous
//        let semaphore = DispatchSemaphore(value: 0)
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] {
//                dict = json!
//            }
//
//            semaphore.signal()
//        }
//
//        task.resume()
//        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
//
//        return dict
//    }
    
    // Implement AVAudioPlayerDelegate "did finish" callback to cleanup and notify listener of completion.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player?.delegate = nil
        self.player = nil
        self.busy = false
        
        self.completionHandler!()
        self.completionHandler = nil
    }
}
