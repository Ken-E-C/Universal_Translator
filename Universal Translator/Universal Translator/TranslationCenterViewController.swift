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


class TranslationCenterViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

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
        
        if TranslationManager.sharedInstance.supportedLanguages.isEmpty {
            fetchSupportedLanguagesList()
        }

    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let capturedText = capturedTextView.text ?? ""
        
        switch textView {
        case capturedTextView:
//            let alert = UIAlertController(title: "Translation in Progress", message: "", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//                NSLog("The \"OK\" alert occured.")
//            }))
            SwiftSpinner.show("Starting Translation")
            //self.present(alert, animated: true, completion: nil)
            
            
            
            
            //detects the source Language
            if detectLanguageEnableSwitch.isOn {
                DispatchQueue.main.async {
                    SwiftSpinner.sharedInstance.title = "Detecting Language"
                }
                
                TranslationManager.sharedInstance.detectLanguage(forText: capturedTextView.text) { (language) in
                    
                    
//                    if alert.isFirstResponder {
//                        alert.dismiss(animated: true, completion: nil)
//                    }
                    
                    TranslationManager.sharedInstance.sourceLanguageCode = language
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
