//
//  SettingsViewController.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 7/10/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    

    @IBOutlet weak var settingsTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.rowHeight = UITableView.automaticDimension
        settingsTableView.estimatedRowHeight = 600
        
//        let LanguageSettingCell = UINib(nibName: "LanguageSettingCell", bundle: Bundle.main)
//        let BluetoothEnableCell = UINib(nibName: "BluetoothEnableCell", bundle: Bundle.main)
//        let GestureEnableCell = UINib(nibName: "GeatureEnableCell", bundle: Bundle.main)
//        let LanguageDetectEnableCell = UINib(nibName: "LanguageDetectEnableCell", bundle: Bundle.main)
//        let VoiceOutputEnableCell = UINib(nibName: "VoiceOutputEnableCell", bundle: Bundle.main)
//        settingsTableView.register(nil, forCellReuseIdentifier: "LanguageSettingCell")
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return settingsTableView.dequeueReusableCell(withIdentifier: "LanguageSettingCell", for: indexPath)
        case 1:
            return settingsTableView.dequeueReusableCell(withIdentifier: "BluetoothEnableCell", for: indexPath)
        case 2:
            return settingsTableView.dequeueReusableCell(withIdentifier: "GeatureEnableCell", for: indexPath)
        case 3:
            return settingsTableView.dequeueReusableCell(withIdentifier: "LanguageDetectEnableCell", for: indexPath)
        case 4:
            return settingsTableView.dequeueReusableCell(withIdentifier: "VoiceOutputEnableCell", for: indexPath)
        default:
            fatalError("unknown setting being loaded")
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
