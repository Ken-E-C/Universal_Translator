//
//  ViewController.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/11/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//
import Foundation
import UIKit

class TranslationCenterViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var capturedTextView: UITextView!
    @IBOutlet weak var detectLanguageEnableSwitch: UISwitch!
    @IBOutlet weak var localLanguageTextField: UITextField!
    
    @IBOutlet weak var startTranslationStatusButton: UIButton!
    
    @IBOutlet weak var translatedTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        capturedTextView.delegate = self
        localLanguageTextField.delegate = self
        
        startTranslationStatusButton.layer.cornerRadius = 5
    
    
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TranslationCenterViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }

    func textViewDidEndEditing(_ textView: UITextView) {
        switch textView {
        case capturedTextView:
            let alert = UIAlertController(title: "Translation in Progress", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
            if detectLanguageEnableSwitch.isOn {
                TranslationManager.sharedInstance.detectLanguage(forText: capturedTextView.text) { (language) in
                    
                    if alert.isFirstResponder {
                        alert.dismiss(animated: true, completion: nil)
                    }
                    
                    let detectedLanguageAlert = UIAlertController(title: "Language Detected", message: "\(language ?? "No language") was detected", preferredStyle: .alert)
                    detectedLanguageAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                        NSLog("The \"OK\" alert occured.")
                    }))
                    self.present(detectedLanguageAlert, animated: true, completion: nil)
                }
            }
            
        default:
            fatalError("unknown field edited: \(textView)")
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
 
}
