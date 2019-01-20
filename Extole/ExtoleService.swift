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
 
 - Todo:
    - Use Codable for JSON.  You’re doing too much work.  https://benscheirman.com/2017/06/swift-json/
    - Use ResultType for returns.  https://www.swiftbysundell.com/posts/the-power-of-result-types-in-swift.
 */
public class ExtoleService {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")
    
    let extoleApiUrls = ["token": "/api/v4/token",
                         "me": "/api/v4/me"
                        ]
    
    let session : URLSession
    let decoder = JSONDecoder()
    public let referralDomain : String
    public var accessToken : ExtoleAccessToken?
    
    /**
     Initializes a new instances of an Extole framework for accessing a referral page.
     
     - Parameters
        - referralDomain: the domain of the referral such as "https://refer.ricardosf.com".
      - Returns the Extole object used formaking additional API calls
     */
    public init(referralDomain : String) {
        self.referralDomain = referralDomain
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }
    
    /**
      Retreives the access token which identifies this user. If the token is already available in
      the service it will be returned, otherwise a new token will be created.
     
     - Parameters
        - completion: callback method which returns the token in the event of a success or an error
    */
    public func getToken(completion: @escaping (ExtoleAccessToken?, ExtoleError?)->()) {
        // If the token is already assigned in the Service it will be returned until a
        // delete token method is called
        if(self.accessToken != nil) {
            completion(self.accessToken, nil)
        }
        
        let tokenUrlString = referralDomain + extoleApiUrls["token"]!
        let tokenUrl = URL(string: tokenUrlString)
        
        os_log("Making request to URL %@", log: customLog, type: .debug, tokenUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: tokenUrl!) { (data, response, error) in
            if let data = data {
                if let accessToken = try? self.decoder.decode(ExtoleAccessToken.self, from: data) {
                    self.accessToken = accessToken
                    completion(self.accessToken, nil)
                } else {
                    if let extoleError = try? self.decoder.decode(ExtoleError.self, from: data) {
                        completion(nil, extoleError)
                    } else {
                        completion(nil, ExtoleError(message: "Could not decode JSON error message"))
                    }
                }
            } else {
                completion(nil, ExtoleError(message: "No data received from API request"))
            }
        }
        task.resume()
    
    }
    
    /**
     Retreives the current user from the API.
     
     - Parameters
        - completion: callback method which returns the user in the event of a success or an error
     */
    public func getMe(completion: @escaping (ExtolePerson?, ExtoleError?)->()) {
        self.getToken() { (token, error) in
            if let token = token {
                let meUrlString = self.referralDomain + self.extoleApiUrls["me"]!
                let meUrl = URL(string: meUrlString)
                var request = URLRequest(url: meUrl!)
                request.setValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")
                let task = self.session.dataTask(with: request) { (data, response, error) in
                    if let data = data {
                        if let person = ExtolePerson(fromData: data) {
                            completion(person, nil)
                        } else {
                            if let extoleError = try? self.decoder.decode(ExtoleError.self, from: data) {
                                completion(nil, extoleError)
                            } else {
                                completion(nil, ExtoleError(message: "Could not decode JSON error message"))
                            }                        }
                    } else {
                        completion(nil, ExtoleError(message: "No data received from API request"))
                    }

                }
                task.resume()
                
            } else {
                completion(nil, error)
            }
        }
    }
    
    public func updateMe(person: ExtolePerson, completion: @escaping (ExtolePerson?, ExtoleError?)->()) {
        self.getToken() { (token, error) in
            if let token = token {
                let meUrlString = self.referralDomain + self.extoleApiUrls["me"]!
                let meUrl = URL(string: meUrlString)
                var request = URLRequest(url: meUrl!)
                request.httpMethod = "POST"
                request.setValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")
                
                /*
                let task = self.session.dataTask(with: request) { (data, response, error) in
                    if let data = data {
                        if let person = ExtolePerson(fromData: data) {
                            completion(person, nil)
                        } else {
                            completion(nil, ExtoleError(fromData: data))
                        }
                    } else {
                        completion(nil, ExtoleError(message: "No data received from API request"))
                    }
                    
                }
                task.resume()
                */
                
            } else {
                completion(nil, error)
            }
        }
    }
}

/**
 An Extole Access Token represents access to a single user at Extole.
 */
public class ExtoleAccessToken : Codable, CustomStringConvertible {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")
    
    // Setup bindings from JSON to properties
    enum CodingKeys : String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in" // TODO: date conversion
        case scopes
        case capabilities
    }
    
    public var description: String {
        return self.accessToken
    }
        
    public var accessToken : String
    public var expiresIn : Int?
    public var scopes : [String]?
    public var capabilities : [String]?
    public var jsonToken: String?
    
    /**
      Init from a String access token which can be useful if the consumers token is stored
      in local cache as part of creating the system.
    */
    public init(accessToken : String) {
        self.accessToken = accessToken
    }
}

public class ExtolePerson {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")
    
    public var personId : String?
    public var email : String?
    public var partnerUserId : String?
    public var firstName : String?
    public var lastName : String?
    public var profilePictureUrl : String?
    public var jsonPerson : String?
    
    init() {
    
    }
    
    init?(fromData: Data) {
        if let jsonPerson = String(data: fromData, encoding: String.Encoding.utf8) {
            self.jsonPerson = jsonPerson
            os_log("Creating Person from URL Data Object: %@", log: self.customLog, type: .debug, jsonPerson)
        }
        
        // {"id":"6646217761789432116","email":null,"first_name":null,"last_name":null,"profile_picture_url":null,"partner_user_id":null,"cookie_consent":null,"cookie_consent_type":null,"processing_consent":null,"processing_consent_type":null,"parameters":{}}
        if let json = try? JSONSerialization.jsonObject(with: fromData, options: []) as! [String: AnyObject] {
            if let personId = json["id"] as? String {
                
                self.personId = personId
                
                if let email = json["email"] as? String {
                  self.email = email
                }
                if let partnerUserId = json["partner_user_id"] as? String {
                    self.partnerUserId = partnerUserId
                }
                if let firstName = json["first_name"] as? String {
                    self.firstName = firstName
                }
                if let lastName = json["last_name"] as? String {
                    self.lastName = lastName
                }
                if let profilePictureUrl = json["profile_picture_url"] as? String {
                    self.profilePictureUrl = profilePictureUrl
                }
                // TODO: cookie_consent,cookie_consent_type,processing_consent,processing_consent_type,parameters
                
                os_log("Person Object Created with Person Id %@", log: self.customLog, type: .debug, personId)
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        os_log("Creating Person from URL Data Object", log: self.customLog, type: .debug)
    }
}



public class ExtoleError : Codable {
    public var uniqueId = "sdk" + UUID().uuidString
    public var httpStatusCode : Int?
    public var errorCode : String?
    public var jsonError : String?
    public var message : String?
    
    // Setup bindings from JSON to properties
    // TODO: Parameters
    enum CodingKeys : String, CodingKey {
        case uniqueId = "unique_id"
        case httpStatusCode = "http_status_code" // TODO: date conversion
        case errorCode = "code"
        case message
    }

    
    init(message:String) {
        self.message = message
    }
    
    /*
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
    */
}
