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
    @IBOutlet weak var detectLanguageEnableSwitch: UISwitch!
    @IBOutlet weak var localLanguageTextField: UITextField!
    @IBOutlet weak var targetLanguageTextField: UITextField!
    @IBOutlet weak var outputVoiceTextField: UITextField!
    
    @IBOutlet weak var startTranslationStatusButton: UIButton!
    
    @IBOutlet weak var translatedTextView: UITextView!
    
    var languagePicker = UIPickerView()
    var voicePicker = UIPickerView()
    var audioData: NSMutableData!
    
    @IBOutlet weak var voiceEnabledSwitch: UISwitch!
    
    let SAMPLE_RATE = 16000
    var capturedLocalLanguageTranscript = String()
    var translatedLanguageTranscript = String()
    //MARK: Init methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        languagePicker.delegate = self
        languagePicker.dataSource = self
        
        voicePicker.delegate = self
        voicePicker.dataSource = self
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector (pickerDoneButtonPressed))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector (pickerCancelButtonPressed))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true

        
        capturedTextView.delegate = self
        translatedTextView.delegate = self
        
        localLanguageTextField.delegate = self
        localLanguageTextField.inputView = languagePicker
        localLanguageTextField.inputAccessoryView = toolBar
        
        targetLanguageTextField.delegate = self
        targetLanguageTextField.inputView = languagePicker
        targetLanguageTextField.inputAccessoryView = toolBar
        targetLanguageTextField.text = LanguageManager.sharedInstance.selectedTargetLang.languageName
        outputVoiceTextField.delegate = self
        outputVoiceTextField.inputView = voicePicker
        outputVoiceTextField.inputAccessoryView = toolBar
        
        startTranslationStatusButton.layer.cornerRadius = 5
        
        translatedTextView.text = ""
    
    
        
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
            outputVoiceTextField.text = VoiceManager.sharedInstance.selectedVoice?.voiceName
            
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
                    self.voiceEnabledSwitch.isEnabled = true
                    self.outputVoiceTextField.becomeFirstResponder()
                }
                else {
                    self.voiceEnabledSwitch.isEnabled = false
                    self.outputVoiceTextField.text = ""
                }
            }
        }
        else if outputVoiceTextField.isEditing {
            let selectedRow = voicePicker.selectedRow(inComponent: 0)
            let selectedVoice = !VoiceManager.sharedInstance.availableRegionalVoices.isEmpty ? VoiceManager.sharedInstance.getRegionalTags()[selectedRow] : nil
            VoiceManager.sharedInstance.selectedVoice = selectedVoice
            
            DispatchQueue.main.async {
                if let verifiedSelectedVoice = selectedVoice {
                    self.outputVoiceTextField.text = verifiedSelectedVoice.voiceName
                }
                else {
                    self.outputVoiceTextField.text = ""
                }
                
            }
        }
        view.endEditing(true)
        
    }
    
    @objc func pickerCancelButtonPressed() {
        view.endEditing(true)
    }
    //MARK: Text Based language Detection methods
    func textViewDidEndEditing(_ textView: UITextView) {
        let capturedText = capturedTextView.text ?? ""
        
        switch textView {
        case capturedTextView:

            SwiftSpinner.show("Starting Translation")
            //detects the source Language
            if detectLanguageEnableSwitch.isOn {
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
            
        default:
            fatalError("unknown field edited: \(textView)")
        }
    }
    
    private func startTranslation(capturedText: String) {
        TranslationManager.sharedInstance.textToTranslate = capturedText
        TranslationManager.sharedInstance.translate { (translatedText) in
            guard let verifiedTranslatedText = translatedText else {return}
            self.translatedLanguageTranscript = verifiedTranslatedText
            if self.voiceEnabledSwitch.isOn {
                //start text to Speech translation
                VoiceManager.sharedInstance.speak(text: self.translatedLanguageTranscript ?? "", completion: {
                    print("tts completed")
                })
            }
            DispatchQueue.main.async {
                self.translatedTextView.text = verifiedTranslatedText
                SwiftSpinner.show(duration: 0.7, title: "Translation Successful")
            }
            //read out speech
            
            
        }
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
                    } else if let response = response {
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
                            self.startTranslation(capturedText: self.capturedLocalLanguageTranscript)
                        }
                    }
            })
            self.audioData = NSMutableData()
        }
    }
    
    
}
