//
//  Extole.swift
//  ExtoleTests
//
//  Created by Jordan Reed on 1/12/19.
//  Copyright © 2019 Extole, Inc. All rights reserved.
//

import Foundation
import os

class ExtoleService {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")
    
    let session : URLSession
    let referralDomain : String
    var accessToken : String?
    
    /**
     Initializes a new instances of an Extole framework for accessing a referral page.
     
     - Parameters
        - referralDomain: the domain of the referral such as "https://refer.ricardosf.com".
      - Returns the Extole object used formaking additional API calls
     */
    init(referralDomain : String) {
        self.referralDomain = referralDomain
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }
    
    func getToken(completion: @escaping (String?)->()) {
        let tokenUrlString = referralDomain + "/api/v4/token"
        let tokenUrl = URL(string: tokenUrlString)
        os_log("Making request to URL %@", log: customLog, type: .debug, tokenUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: tokenUrl!) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                os_log("Received response status code request to URL %{public}@ is %d", log: self.customLog, type: .debug, tokenUrl?.absoluteString ?? "nil", httpResponse.statusCode)
            }
            


            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
                    if let access_token = json["access_token"] as? String {
                        os_log("JSON Object Created with token %@", log: self.customLog, type: .debug, access_token)
                        
                        self.accessToken = access_token
                        completion(self.accessToken)
                    }
                    
                } catch let error as NSError {
                    os_log("JSON Object Failed %@", log: self.customLog, type: .debug, error.localizedDescription)
                }
            }

            if let returnString = String(data: data!, encoding: String.Encoding.utf8) {
                os_log("Received response data: %@", log: self.customLog, type: .debug, returnString)
            }
            
        }
        task.resume()

    }
    
    func getMe(completion: @escaping (Any?)->()) {
        let meUrlString = referralDomain + "/api/v4/me"
        let meUrl = URL(string: meUrlString)
        os_log("Making request to URL %@", log: customLog, type: .debug, meUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: meUrl!) { (data, response, error) in
          if let data = data {
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            completion(json)
          }
        }
        task.resume()
    }
    
    func getLink(forEmail : String) -> URL? {
        // 1. Validate Access Token is Valid for Email
        //
        return nil
    }
}
