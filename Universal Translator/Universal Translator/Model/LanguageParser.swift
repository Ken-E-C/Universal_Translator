//
//  ietfParser.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/14/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import SwiftyJSON
class LanguageParser {
    
    var languageTags: JSON?
    
    init() {
        if let path = Bundle.main.path(forResource: "ietf-language-tags", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                languageTags = try JSON(data: data)
                
            } catch {
                fatalError("Error loading ietf JSON file")
            }
        }
    }
    
}
