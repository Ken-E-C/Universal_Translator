//
// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import Foundation
import googleapis
import AVFoundation



let HOST = "speech.googleapis.com"

typealias SpeechRecognitionCompletionHandler = (StreamingRecognizeResponse?, NSError?) -> (Void)

class SpeechRecognitionManager {
    var sampleRate: Int = 16000
    private var streaming = false

    private var client : Speech!
    private var writer : GRXBufferedPipe!
    private var call : GRPCProtoCall!

    static let sharedInstance = SpeechRecognitionManager()
    
    private var timeoutTimer: Timer?
    
    var timeoutCallback: (()->Void)?
    

    func streamAudioData(_ audioData: NSData, bcp47LangCode: String, completion: @escaping SpeechRecognitionCompletionHandler) {
        if (!streaming) {
            // if we aren't already streaming, set up a gRPC connection
            client = Speech(host:HOST)
            writer = GRXBufferedPipe()
            
            call = client.rpcToStreamingRecognize(withRequestsWriter: writer,
                                                    eventHandler:
            { (done, response, error) in
                if self.streaming {
                    completion(response, error as NSError?)
                    if !done {
                        self.resetTimeoutTimer()
                    }
                    else {
                        self.timeoutTimer?.invalidate()
                    }
                }
            })
            // authenticate using an API key obtained from the Google Cloud Console
            call.requestHeaders.setObject(NSString(string:googleCloudAPIKey),
                                        forKey:NSString(string:"X-Goog-Api-Key"))
            // if the API key has a bundle ID restriction, specify the bundle ID like this
            call.requestHeaders.setObject(NSString(string:Bundle.main.bundleIdentifier!),
                                            forKey:NSString(string:"X-Ios-Bundle-Identifier"))

            print("HEADERS:\(String(describing: call.requestHeaders))")

            call.start()
            streaming = true
            resetTimeoutTimer()

            // send an initial request message to configure the service
            let recognitionConfig = RecognitionConfig()
            recognitionConfig.encoding =  .linear16
            recognitionConfig.sampleRateHertz = Int32(sampleRate)
            recognitionConfig.languageCode = bcp47LangCode
            recognitionConfig.maxAlternatives = 30
            recognitionConfig.enableWordTimeOffsets = true

            let streamingRecognitionConfig = StreamingRecognitionConfig()
            streamingRecognitionConfig.config = recognitionConfig
            streamingRecognitionConfig.singleUtterance = false
            streamingRecognitionConfig.interimResults = true

            let streamingRecognizeRequest = StreamingRecognizeRequest()
            streamingRecognizeRequest.streamingConfig = streamingRecognitionConfig

            writer.writeValue(streamingRecognizeRequest)
        }
        // send a request message containing the audio data
        let streamingRecognizeRequest = StreamingRecognizeRequest()
        streamingRecognizeRequest.audioContent = audioData as Data
        writer.writeValue(streamingRecognizeRequest)
        
    }

    func stopStreaming() {
        if (!streaming) {
          return
        }
        writer.finishWithError(nil)
        streaming = false
        timeoutTimer?.invalidate()
    }

    func isStreaming() -> Bool {
        return streaming
    }
    
    private func resetTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timeoutTimerFired), userInfo: nil, repeats: false)
    }
    
    @objc private func timeoutTimerFired() {
        stopStreaming()
        //notify TranslationCenter that the Speech Recognition Manager Timed Out
        guard let verifiedTimeoutCallback = timeoutCallback else {
            fatalError("No timeout callback was initialized in the SpeechRecognitionManager")
        }
        verifiedTimeoutCallback()
    }
}

