//
//  ViewController.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/11/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//
import Foundation
import UIKit
import SwiftSpinner
import googleapis
import AVFoundation



class TranslationCenterViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, LanguageManagerDelegate, AudioManagerDelegate {
 

    @IBOutlet weak var capturedTextView: UITextView!
    //@IBOutlet weak var detectLanguageEnableSwitch: UISwitch!
    @IBOutlet weak var localLanguageTextField: UITextField!
    @IBOutlet weak var targetLanguageTextField: UITextField!
    //@IBOutlet weak var outputVoiceTextField: UITextField!
    
    @IBOutlet weak var startTranslationStatusButton: UIButton!
    @IBOutlet weak var inputSelectorButton: UIButton!
    @IBOutlet weak var outputSelectorButton: UIButton!
    
    @IBOutlet weak var translatorControlsSubview: UIView!
    @IBOutlet weak var translatedTextView: UITextView!
    
    var languagePicker = UIPickerView()
    var voicePicker = UIPickerView()
    var audioData: NSMutableData!
    
    //@IBOutlet weak var voiceEnabledSwitch: UISwitch!
    
    let SAMPLE_RATE = 16000
    var capturedLocalLanguageTranscript = String()
    var translatedLanguageTranscript = String()
    
    var sessionInProgress = false
    
    var timeoutTimer: Timer?
    
    //MARK: Init methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        BoseWearableDeviceManager.sharedInstance.delegate = self
        
        languagePicker.delegate = self
        languagePicker.dataSource = self
        
        voicePicker.delegate = self
        voicePicker.dataSource = self
        
        let pickerToolBar = UIToolbar()
        pickerToolBar.barStyle = UIBarStyle.default
        pickerToolBar.isTranslucent = true
        pickerToolBar.tintColor = UIColor(red: 31/255, green: 117/255, blue: 254/255, alpha: 1)
        pickerToolBar.sizeToFit()
        
        let keyboardToolBar = UIToolbar()
        keyboardToolBar.barStyle = UIBarStyle.default
        keyboardToolBar.isTranslucent = true
        keyboardToolBar.tintColor = UIColor(red: 31/255, green: 117/255, blue: 254/255, alpha: 1)
        keyboardToolBar.sizeToFit()
        
        let pickerDoneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector (pickerDoneButtonPressed))
        let pickerSpaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let pickerCancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector (cancelButtonPressed))
        
        let keyboardSpaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let keyboardCancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector (cancelButtonPressed))
        let keyboardTranslateButton = UIBarButtonItem(title: "Translate", style: UIBarButtonItem.Style.plain, target: self, action: #selector (keyboardTranslateButtonPressed))
        
        pickerToolBar.setItems([pickerCancelButton, pickerSpaceButton, pickerDoneButton], animated: false)
        pickerToolBar.isUserInteractionEnabled = true
        
        keyboardToolBar.setItems([keyboardCancelButton, keyboardSpaceButton, keyboardTranslateButton], animated: false)
        keyboardToolBar.isUserInteractionEnabled = true
        
        
        
        
        capturedTextView.delegate = self
        capturedTextView.inputAccessoryView = keyboardToolBar
        
        translatedTextView.delegate = self
        translatedTextView.text = ""
        
        localLanguageTextField.delegate = self
        localLanguageTextField.inputView = languagePicker
        localLanguageTextField.inputAccessoryView = pickerToolBar
        
        targetLanguageTextField.delegate = self
        targetLanguageTextField.inputView = languagePicker
        targetLanguageTextField.inputAccessoryView = pickerToolBar
        targetLanguageTextField.text = LanguageManager.sharedInstance.selectedTargetLang.languageName
//        outputVoiceTextField.delegate = self
//        outputVoiceTextField.inputView = voicePicker
//        outputVoiceTextField.inputAccessoryView = pickerToolBar
        
        startTranslationStatusButton.layer.cornerRadius = 75
        startTranslationStatusButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        startTranslationStatusButton.layer.masksToBounds = false
        startTranslationStatusButton.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        startTranslationStatusButton.layer.shadowOpacity = 1.0
        startTranslationStatusButton.layer.shadowRadius = 0.75
        
        inputSelectorButton.layer.cornerRadius = 15
        inputSelectorButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        inputSelectorButton.layer.masksToBounds = false
        inputSelectorButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        inputSelectorButton.layer.shadowOpacity = 1.0
        inputSelectorButton.layer.shadowRadius = 0.75
        
        outputSelectorButton.layer.cornerRadius = 15
        outputSelectorButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        outputSelectorButton.layer.masksToBounds = false
        outputSelectorButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        outputSelectorButton.layer.shadowOpacity = 1.0
        outputSelectorButton.layer.shadowRadius = 0.75
        
        translatorControlsSubview.layer.cornerRadius = 64
        translatorControlsSubview.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        translatorControlsSubview.layer.masksToBounds = false
        translatorControlsSubview.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        translatorControlsSubview.layer.shadowOpacity = 1.0
        translatorControlsSubview.layer.shadowRadius = 0.75
        
        
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TranslationCenterViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        
        LanguageManager.sharedInstance.TCViewController = self
        AudioManager.sharedInstance.delegate = self
        if TranslationManager.sharedInstance.supportedLanguages.isEmpty {
            fetchSupportedLanguagesList()
        }
        

    }
    override func viewDidAppear(_ animated: Bool) {
        //MARK: Request necessary permissions
        if !LanguageManager.sharedInstance.checkPermissions(){
            let permissionsAlert = UIAlertController(title: "Error requesting location permission", message: "The app can still work without location services. However, the translation would be more effective if the app can identify the language ahead of time.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            permissionsAlert.addAction(okAction)
            present(permissionsAlert, animated: true, completion: nil)
        }
        
        if !AudioManager.sharedInstance.checkPermissions() {
            let permissionsAlert = UIAlertController(title: "Error requesting mic permission", message: "Audio transcrription will be disabled. If you wish to enable, please allow use of the mic.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            permissionsAlert.addAction(okAction)
            present(permissionsAlert, animated: true, completion: nil)
        }
        SwiftSpinner.show("Inferring Local Language")
        LanguageManager.sharedInstance.inferLanguage()
    }
    
    //MARK: Language Setup methods
    
    func fetchSupportedLanguagesList() {
        TranslationManager.sharedInstance.fetchSupportedLanguages { (isSuccessful) in
            if !isSuccessful {
                let languageNotFetchedAlert = UIAlertController(title: "Error loading Supported Languages", message: "There was an error with retrieving the list of supported languages. Check your internet connection and reload the app.", preferredStyle: .alert)
                languageNotFetchedAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(languageNotFetchedAlert, animated: true, completion: nil)
            }
        }
    }
    
    func languageTagsUpdated() {
        SwiftSpinner.hide()
        if LanguageManager.sharedInstance.detectedLangTags.isEmpty {
            //display error message if a language could not be inferred
            let languageNotinferredAlert = UIAlertController(title: "Error Inferring Languages", message: "There was an error with inferring the language using your location. What would you like to do?", preferredStyle: .alert)
            languageNotinferredAlert.addAction(UIAlertAction(title: NSLocalizedString("Detect Language using audio", comment: "Default action"), style: .default, handler: { _ in
                //setup detect language using audio feed
                self.capturedTextView.becomeFirstResponder()
                NSLog("The \"Detect Language audio\" alert occured.")
            }))
            languageNotinferredAlert.addAction(UIAlertAction(title: NSLocalizedString("Detect Language by entering text", comment: "Default action"), style: .default, handler: { _ in
                self.capturedTextView.becomeFirstResponder()
                NSLog("The \"Detect Language text\" alert occured.")
            }))
            languageNotinferredAlert.addAction(UIAlertAction(title: NSLocalizedString("Ignore and continue", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"Ignore and continue\" alert occured.")
            }))
            present(languageNotinferredAlert, animated: true)
        }
        else {
            let selectedLang = LanguageManager.sharedInstance.selectedTargetLang
            localLanguageTextField.text = selectedLang.languageName
            VoiceManager.sharedInstance.setVoiceTag(languageCode: selectedLang.bcp47Tag!)
            VoiceManager.sharedInstance.setRegionalTags(languageCode: selectedLang.bcp47Tag!)
            //outputVoiceTextField.text = VoiceManager.sharedInstance.selectedVoice?.voiceName
            
            if BoseWearableDeviceManager.sharedInstance.activeWearableSession == nil {
                BoseWearableDeviceManager.sharedInstance.searchForDevice()
            }
            
        }
    }
    
    
    //MARK: LanguagePicker Stuff
    func numberOfComponents(in pickerView: UIPickerView) -> Int {

        switch pickerView {
        case languagePicker:
            return 1
        case voicePicker:
            return 1
        default:
            fatalError("unidentified picker was used")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case languagePicker:
            return LanguageParser.sharedInstance.getLanguageTags().count
        case voicePicker:
            return VoiceManager.sharedInstance.getRegionalTags().count
        default:
            fatalError("unidentified picker was used")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch pickerView {
        case languagePicker:
            return LanguageParser.sharedInstance.getLanguageTags()[row].languageName
        case voicePicker:
            return VoiceManager.sharedInstance.getRegionalTags()[row].voiceName
        default:
            fatalError("unidentified picker was used")
        }
    }
    //MARK: Picker and Keyboard Button Methods
    @objc func pickerDoneButtonPressed() {
        
        let selectedRow = languagePicker.selectedRow(inComponent: 0)
        let selectedLang = LanguageParser.sharedInstance.getLanguageTags()[selectedRow]
        if localLanguageTextField.isEditing {
            LanguageManager.sharedInstance.selectedLocalLang = selectedLang
            DispatchQueue.main.async {
                self.localLanguageTextField.text = selectedLang.languageName
            }
        }
        else if targetLanguageTextField.isEditing {
            LanguageManager.sharedInstance.selectedTargetLang = selectedLang
            VoiceManager.sharedInstance.setVoiceTag(languageCode: selectedLang.bcp47Tag!)
            
            VoiceManager.sharedInstance.setRegionalTags(languageCode: selectedLang.bcp47Tag!)
            if VoiceManager.sharedInstance.availableRegionalVoices.isEmpty{
                VoiceManager.sharedInstance.setEquivalentRegionalTags(isoLanguageCode: selectedLang.languageTag!)
            }
            DispatchQueue.main.async {
                self.targetLanguageTextField.text = selectedLang.languageName
                if !VoiceManager.sharedInstance.availableRegionalVoices.isEmpty{
//                    self.voiceEnabledSwitch.isEnabled = true
//                    self.outputVoiceTextField.becomeFirstResponder()
                }
                else {
//                    self.voiceEnabledSwitch.isEnabled = false
//                    self.outputVoiceTextField.text = ""
                }
            }
        }
//        else if outputVoiceTextField.isEditing {
//            let selectedRow = voicePicker.selectedRow(inComponent: 0)
//            let selectedVoice = !VoiceManager.sharedInstance.availableRegionalVoices.isEmpty ? VoiceManager.sharedInstance.getRegionalTags()[selectedRow] : nil
//            VoiceManager.sharedInstance.selectedVoice = selectedVoice
//
//            DispatchQueue.main.async {
//                if let verifiedSelectedVoice = selectedVoice {
//                    //self.outputVoiceTextField.text = verifiedSelectedVoice.voiceName
//                }
//                else {
//                    //self.outputVoiceTextField.text = ""
//                }
//
//            }
//        }
        view.endEditing(true)
        
    }
    
    @objc func cancelButtonPressed() {
        view.endEditing(true)
    }
    
    @objc func keyboardTranslateButtonPressed() {
        view.endEditing(true)
        if !capturedTextView.text.isEmpty{
            startTextBasedTranslation(capturedText: capturedTextView.text!)
        }
    }
    //MARK: Text Based language Detection methods
    
    
    private func startTextBasedTranslation(capturedText: String) {
        if areLanguagesTheSame() {
            return
        }
        SwiftSpinner.show("Starting Translation")
        //detects the source Language
        if /*detectLanguageEnableSwitch.isOn*/ true {
            DispatchQueue.main.async {
                SwiftSpinner.sharedInstance.title = "Detecting Language"
            }
            
            TranslationManager.sharedInstance.detectLanguage(forText: capturedTextView.text) { (language) in
                TranslationManager.sharedInstance.sourceLanguageCode = language
                LanguageManager.sharedInstance.updateDetectedLanguages(languageCode: language ?? "")
                DispatchQueue.main.async {
                    self.localLanguageTextField.text = language
                    SwiftSpinner.sharedInstance.title = "Translating Captured Phrase"
                }
                self.startTranslation(capturedText: capturedText)
                
            }
        } else {
            DispatchQueue.main.async {
                SwiftSpinner.sharedInstance.title = "Translating Captured Phrase"
            }
            
            startTranslation(capturedText: capturedText)
        }
    }
    
    private func startTranslation(capturedText: String) {
        resetTimeoutTimer()
        TranslationManager.sharedInstance.textToTranslate = capturedText
        //let isSwitchOn = self.voiceEnabledSwitch.isOn
        TranslationManager.sharedInstance.translate { (translatedText) in
            guard let verifiedTranslatedText = translatedText else {return}
            self.translatedLanguageTranscript = verifiedTranslatedText
            if /*isSwitchOn*/ true {
                //start text to Speech translation
                VoiceManager.sharedInstance.speak(text: self.translatedLanguageTranscript , completion: {
                    print("tts completed")
                })
            }
            DispatchQueue.main.async {
                self.translatedTextView.text = verifiedTranslatedText
                SwiftSpinner.show(duration: 0.7, title: "Translation Completed")
                self.timeoutTimer?.invalidate()
                self.sessionInProgress = false
                
            }
        }
    }
    
    func areLanguagesTheSame() -> Bool {
        let localLang = LanguageManager.sharedInstance.selectedLocalLang.languageTag
        let targetLang = LanguageManager.sharedInstance.selectedTargetLang.languageTag
        if localLang == targetLang {
            let languageIdenticalAlert = UIAlertController(title: "Error with Selected Local and Target Language", message: "The target language and the local language cannot be the same. Please change either the local or target language", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            languageIdenticalAlert.addAction(okAction)
            present(languageIdenticalAlert, animated: true, completion: nil)
            sessionInProgress = false
            return true
        }
        
        return false
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status and drop into background
        view.endEditing(true)
    }
    
    //MARK: Speech to text post capture processing methods
    
    
    
    @IBAction func startTranslationButtonPressed(_ sender: Any) {
        if !sessionInProgress{
            sessionInProgress = true
            startAudioTranslation()
        }
        
    }
    
    func startAudioTranslation() {
        if areLanguagesTheSame(){
            return
        }
        resetTimeoutTimer()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
        } catch {
            let cantStartRecordingAlert = UIAlertController(title: "Error Starting AudioTranslation", message: "There was a problem starting the audio capture", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            cantStartRecordingAlert.addAction(okAction)
            self.present(cantStartRecordingAlert, animated: true)
        }
        audioData = NSMutableData()
        _ = AudioManager.sharedInstance.prepare(specifiedSampleRate: SAMPLE_RATE)
        SpeechRecognitionManager.sharedInstance.sampleRate = SAMPLE_RATE
        _ = AudioManager.sharedInstance.start()
        DispatchQueue.main.async {
            SwiftSpinner.show("Capturing Speech")
        }
    }
    
    func stopAudio() {
        _ = AudioManager.sharedInstance.stop()
        SpeechRecognitionManager.sharedInstance.stopStreaming()
    }
    
    func processSampleData(_ data: Data) {
        
        audioData.append(data)
        
        // We recommend sending samples in 100ms chunks
        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
            * Double(SAMPLE_RATE) /* samples/second */
            * 2 /* bytes/sample */);
        
        if (audioData.length > chunkSize) {
            SpeechRecognitionManager.sharedInstance.streamAudioData(audioData, bcp47LangCode: LanguageManager.sharedInstance.selectedLocalLang.bcp47Tag!,
                                                                    completion:
                { (response, error) in
                    if let error = error {
                        print("Error with processing captured Speech: \(error.localizedDescription)")
                        self.sessionInProgress = false
                    } else if let response = response {
                        self.resetTimeoutTimer()
                        var finished = false
                        print(response)
                        for result in response.resultsArray! {
                            if let result = result as? StreamingRecognitionResult {
                                if result.isFinal {
                                    finished = true
                                    for alternative in result.alternativesArray{
                                        if let alternative = alternative as? SpeechRecognitionAlternative{
                                            self.capturedTextView.text = alternative.transcript
                                            self.capturedLocalLanguageTranscript = alternative.transcript
                                        }
                                    }
                                }
                            }
                        }
                        //strongSelf.textView.text = response.description
                        if finished {
                            self.stopAudio()
                            DispatchQueue.main.async {
                                SwiftSpinner.show("Translating speech")
                            }
                            self.startTranslation(capturedText: self.capturedLocalLanguageTranscript)
                        }
                    }
            })
            self.audioData = NSMutableData()
        }
    }
    
    func headNodDetected() {
        
        if !sessionInProgress {
            sessionInProgress = true
            startAudioTranslation()
        }
        
    }
    
    func headShakeDetected() {
        if sessionInProgress{
            timeoutTimer?.invalidate()
            terminateSession(message: "Session Cancelled")
        }
        
    }
    
    @objc func timeoutTimerFired() {
        timeoutTimer?.invalidate()
        terminateSession()
    }
    
    func terminateSession(message: String = "Session Timed Out") {
        if AudioManager.sharedInstance.isRecording {
            AudioManager.sharedInstance.stop()
        }
        if SpeechRecognitionManager.sharedInstance.isStreaming(){
            SpeechRecognitionManager.sharedInstance.stopStreaming()
        }
        sessionInProgress = false
        SwiftSpinner.show(duration: 1.3, title: message)
        
    }
    
    private func resetTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timeoutTimerFired), userInfo: nil, repeats: false)
        
    }
    
    //Bose Wearable Config Stuff
    
    
}
