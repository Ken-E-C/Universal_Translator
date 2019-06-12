//
//  TranslationAPIEnums.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/11/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import SwiftyJSON

enum TranslationAPI {
    case detectLanguage
    case translate
    case supportedLanguages
    
    func getURL() -> String {
        var urlString = ""
        
        switch self {
        case .detectLanguage:
            urlString = "https://translation.googleapis.com/language/translate/v2/detect"
            
        case .translate:
            urlString = "https://translation.googleapis.com/language/translate/v2"
            
        case .supportedLanguages:
            urlString = "https://translation.googleapis.com/language/translate/v2/languages"
        }
        
        return urlString
    }
    
    func getHTTPMethod() -> String {
        if self == .supportedLanguages {
            return "GET"
        } else {
            return "POST"
        }
    }
}

struct TranslationLanguage {
    var code: String?
    var name: String?
}

class TranslationManager: NSObject {
    
    static let sharedInstance = TranslationManager()
    
    private let apiKey = googleCloudAPIKey
    
    var supportedLanguages = [TranslationLanguage]()
    
    private func makeRequest(usingTranslationAPI api: TranslationAPI, urlParams: [String: String], completion: @escaping (_ results: Data?) -> Void) {
        
        if var components = URLComponents(string: api.getURL()) {
            for (key,value) in urlParams {
                components.queryItems?.append(URLQueryItem(name: key, value: value))
            }
            if let url = components.url {
                var request = URLRequest(url: url)
                request.httpMethod = api.getHTTPMethod()
                
                let session = URLSession(configuration: .default)
                
                let task = session.dataTask(with: request) { (results, response, error) in
                    if let error = error {
                        print(error)
                        completion(nil)
                    }
                    else {
                        if let response = response as? HTTPURLResponse {
                            if response.statusCode == 200 || response.statusCode == 201 {

                            if let verifiedResults = results{
                                completion(verifiedResults)
                            }
                            else {
                                completion(nil)
                            }
                        }
                    }
                }
            }
            task.resume()
            }
        }
    }
    
    func detectLanguage(forText text: String, completion: @escaping (_ language: String?) -> Void) {
        let urlParams = ["key": apiKey, "q": text]
        
        makeRequest(usingTranslationAPI: .detectLanguage, urlParams: urlParams) { (results) in
            guard let results = results else {completion(nil); return}
            
            do {
                let data = try JSON(data: results)
                
                if let language = data["data"]["detections"][0]["language"].string {
                    completion(language)
                }
                else {
                    completion(nil)
                }
            }
            catch {
                print("error with parsing data to JSON file format \(error)")
            }
        }
        
            
            
                
            
            
            
//            if let data = results["data"] as? [String: Any], let detections = data["detections"] as? [[[String: Any]]]{
//                var detectedLanguages = [String]()
//
//                for detection in detections {
//                    for currentDetection in detection{
//                        if let language = currentDetection["language"] as? String {
//                            detectedLanguages.append(language)
//                        }
//                    }
//                }
//
//                if detectedLanguages.count > 0 {
//                    completion(detectedLanguages[0])
//                }
//                else {
//                    completion(nil)
//                }
//            }
//        }
    }
    
    
    func fetchSupportedLanguages(completion: @escaping (_ success: Bool) -> Void) {
        
    }
        
}




