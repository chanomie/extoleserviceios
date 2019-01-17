//
//  Extole.swift
//  ExtoleTests
//
//  Created by Jordan Reed on 1/12/19.
//  Copyright © 2019 Extole, Inc. All rights reserved.
//

import Foundation
import os

// TODO: Create a dictionary of all the URLS to be called

/**
 Access various services methods of the Extole Consumer API (https://developer.extole.com)
 */
class ExtoleService {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")
    
    let extoleApiUrls = ["token": "/api/v4/token",
                         "me": "/api/v4/me"
                        ]
    
    let session : URLSession
    let referralDomain : String
    var accessToken : ExtoleAccessToken?
    
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
    
    /**
      Retreives the access token which identifies this user. If the token is already available in
      the service it will be returned, otherwise a new token will be created.
     
     - Parameters
        - completion: callback method which returns the token in the event of a success
    */
    func getToken(completion: @escaping (ExtoleAccessToken?)->()) {
        // TODO: Error handling for invalid URL or other errors
        if(self.accessToken != nil) {
            completion(self.accessToken)
        }
        
        let tokenUrlString = referralDomain + extoleApiUrls["token"]!
        let tokenUrl = URL(string: tokenUrlString)
        os_log("Making request to URL %@", log: customLog, type: .debug, tokenUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: tokenUrl!) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                os_log("Received response status code request to URL %{public}@ is %d", log: self.customLog, type: .debug, tokenUrl?.absoluteString ?? "nil", httpResponse.statusCode)
            }
            
            if let data = data {
                if let accessToken = ExtoleAccessToken(fromData: data) {
                    self.accessToken = accessToken
                    completion(self.accessToken)
                } else {
                    completion(nil)
                }
            }

            if let returnString = String(data: data!, encoding: String.Encoding.utf8) {
                os_log("Received response data: %@", log: self.customLog, type: .debug, returnString)
            }
            
        }
        task.resume()

    }
    
    /**
     Retreives the access token which identifies this user. If the token is already available in
     the service it will be returned, otherwise a new token will be created.
     
     - Parameters
     - completion: callback method which returns the token in the event of a success
     */
    func getMe(completion: @escaping (ExtolePerson?)->()) {
        let meUrlString = referralDomain + extoleApiUrls["me"]!
        let meUrl = URL(string: meUrlString)
        os_log("Making request to URL %@", log: customLog, type: .debug, meUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: meUrl!) { (data, response, error) in
          if let data = data {
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            // completion(json)
          }
        }
        task.resume()
    }
}


class ExtoleAccessToken : CustomStringConvertible {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")
    
    var description: String {
        return self.accessToken
    }
        
    var accessToken : String = ""
    var expiresIn : Int?
    var scopes : [String]?
    var capabilities : [String]?
    
    init(accessToken : String) {
        self.accessToken = accessToken
    }
    
    init?(fromData: Data) {
        os_log("Creating Access Token from URL Data Object", log: self.customLog, type: .debug)
        if let json = try? JSONSerialization.jsonObject(with: fromData, options: []) as! [String: AnyObject] {
            if let accessToken = json["access_token"] as? String,
                let expiresIn = json["expires_in"] as? Int {

                self.accessToken = accessToken
                self.expiresIn = expiresIn
                
                os_log("JSON Object Created with token %@", log: self.customLog, type: .debug, accessToken)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

class ExtolePerson {
}
