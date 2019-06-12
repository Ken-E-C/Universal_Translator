//
//  ViewController.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/11/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var capturedTextField: UITextView!
    @IBOutlet weak var detectLanguageEnableSwitch: UISwitch!
    @IBOutlet weak var localLanguageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        capturedTextField.delegate = self
    }


}

