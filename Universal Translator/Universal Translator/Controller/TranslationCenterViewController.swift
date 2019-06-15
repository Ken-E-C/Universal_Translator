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


class TranslationCenterViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, LanguageManagerProtocol {

    @IBOutlet weak var capturedTextView: UITextView!
    @IBOutlet weak var detectLanguageEnableSwitch: UISwitch!
    @IBOutlet weak var localLanguageTextField: UITextField!
    @IBOutlet weak var targetLanguageTextField: UITextField!
    
    @IBOutlet weak var startTranslationStatusButton: UIButton!
    
    @IBOutlet weak var translatedTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        capturedTextView.delegate = self
        translatedTextView.delegate = self
        localLanguageTextField.delegate = self
        targetLanguageTextField.delegate = self
        
        targetLanguageTextField.text = TranslationManager.sharedInstance.targetLanguageCode
        startTranslationStatusButton.layer.cornerRadius = 5
        
        translatedTextView.text = ""
    
    
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TranslationCenterViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        LanguageManager.sharedInstance.TCViewController = self
        if TranslationManager.sharedInstance.supportedLanguages.isEmpty {
            fetchSupportedLanguagesList()
        }
        

    }
    override func viewDidAppear(_ animated: Bool) {
        if !LanguageManager.sharedInstance.checkPermissions(){
            let permissionsAlert = UIAlertController(title: "Error requesting permission", message: "The app can still work without location services. However, the translation would be more effective if the app can identify the language ahead of time.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            permissionsAlert.addAction(okAction)
            present(permissionsAlert, animated: true, completion: nil)
        }
        LanguageManager.sharedInstance.inferLanguage()
    }

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
            
            DispatchQueue.main.async {
                self.translatedTextView.text = verifiedTranslatedText
                SwiftSpinner.show(duration: 0.7, title: "Translation Successful")
            }
            
            
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
        if !LanguageManager.sharedInstance.detectedLangTags.isEmpty {
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
    }
 
    @IBAction func localLanguageEntered(_ sender: Any) {
        DispatchQueue.main.async {
            TranslationManager.sharedInstance.sourceLanguageCode = self.localLanguageTextField.text
        }
    }
    
    @IBAction func targetLanguageEntered(_ sender: Any) {
        DispatchQueue.main.async {
            TranslationManager.sharedInstance.targetLanguageCode = self.targetLanguageTextField.text!
        }
        
    }
    
    
    
}
