//
//  Extole.swift
//  ExtoleTests
//
//  Created by Jordan Reed on 1/12/19.
//  Copyright © 2019 Extole, Inc. All rights reserved.
//

import Foundation
import os

/**
 Access various services methods of the Extole Consumer API (https://developer.extole.com)
 
 - Author: Jordan Reed
 - Copyright: Copyright © 2019 Extole, Inc. All rights reserved.
 
 - Properties:
    - referralDomain: the base URL of the referral domain available in the Tech Center
    - accessToken: the token for the current user which is implicitly created and used by other method calls
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
        - completion: callback method which returns the token in the event of a success or an error
    */
    func getToken(completion: @escaping (ExtoleAccessToken?, ExtoleError?)->()) {
        // If the token is already assigned in the Service it will be returned until a
        // delete token method is called
        if(self.accessToken != nil) {
            completion(self.accessToken, nil)
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
                    completion(self.accessToken, nil)
                } else {
                    completion(nil, ExtoleError(fromData: data))
                }
            }
        }
        task.resume()
    }
    
    /**
     Retreives the current user from the API.
     
     - Parameters
        - completion: callback method which returns the user in the event of a success or an error
     */
    func getMe(completion: @escaping (ExtolePerson?, ExtoleError?)->()) {
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

// {"unique_id":"6647332750708663350","http_status_code":400,"code":"invalid_program_domain","message":"The program domain this request was made on is invalid.","parameters":{"program_domain":"refer-badness.extole.com"}}
class ExtoleError {
    var uniqueId = "sdk" + String(NSDate().timeIntervalSince1970 * 1000)
    var httpStatusCode : Int?
    var errorCode : String?
    var jsonError : String?
    var message : String?
    
    init(message:String) {
        self.message = message
    }
    
    init(fromData: Data) {
        if let jsonError = String(data: fromData, encoding: String.Encoding.utf8) {
            self.jsonError = jsonError
        }

        if let json = try? JSONSerialization.jsonObject(with: fromData, options: []) as! [String: AnyObject] {
            if let uniqueId = json["unique_id"] as? String,
                let httpStatusCode = json["http_status_code"] as? Int,
                let errorCode = json["code"] as? String,
                let message = json["message"] as? String {
                
                self.uniqueId = uniqueId
                self.httpStatusCode = httpStatusCode
                self.errorCode = errorCode
                self.message = message
            } else {
                self.message = "SDK could not decode error response, missing error response parameters: " + (self.jsonError ?? "empty json")
            }
        } else {
            self.message = "SDK could not decode error response, JSON parameters missing:" + (self.jsonError ??  "empty json")
        }

    }
}
