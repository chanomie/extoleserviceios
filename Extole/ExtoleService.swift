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

// Internal Notes:
// Codable for JSON - https://benscheirman.com/2017/06/swift-json/
// May want to switch to ResultType returns or wait for it be formally part of the language
//  in Swift 5 - https://www.swiftbysundell.com/posts/the-power-of-result-types-in-swift.
public class ExtoleService {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")

    let extoleApiUrls = ["token": "/api/v4/token",
                         "me": "/api/v4/me"
                        ]

    let session: URLSession
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    public let referralDomain: String
    public var accessToken: ExtoleAccessToken?

    /**
     Initializes a new instances of an Extole framework for accessing a referral page.
     
     - Parameters
        - referralDomain: the domain of the referral such as "https://refer.ricardosf.com".
     - Returns the Extole object used formaking additional API calls
     */
    public init(referralDomain: String) {
        self.referralDomain = referralDomain
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }

    /**
      Retreives the access token which identifies this user. If the token is already available in
      the service it will be returned, otherwise a new token will be returned by Extole.
     
      Also note that Extole will set the token in a cookie and iOS will cache the cookies inside
      of the apps container, so subsequent calls will return the same token between sessions unless
      you clear the cookie.
     
     - Parameters
        - completion: callback method which returns the token in the event of a success or an error
    */
    public func getToken(completion: @escaping (ExtoleAccessToken?, ExtoleError?) -> Void) {
        // If the token is already assigned in the Service it will be returned until a
        // delete token method is called
        if self.accessToken != nil {
            os_log("%{public}@ - Returning cached token %@", log: customLog,
                   type: .debug, #function, self.accessToken?.accessToken ?? "nil")
            completion(self.accessToken, nil)
        }

        let tokenUrlString = referralDomain + extoleApiUrls["token"]!
        let tokenUrl = URL(string: tokenUrlString)

        os_log("%{public}@ - Making GET request to URL %@", log: customLog,
               type: .debug, #function, tokenUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: tokenUrl!) { (data, response, _ error) in
            if let data = data {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let accessToken = try? self.decoder.decode(ExtoleAccessToken.self, from: data) {
                            self.accessToken = accessToken
                            os_log("%{public}@ - Returning new token %@", log: self.customLog,
                                   type: .debug, #function, self.accessToken?.accessToken ?? "nil")
                            completion(self.accessToken, nil)
                        } else {
                            completion(nil, ExtoleError(message: "Could not decode JSON error message"))
                        }
                    } else {
                        os_log("%{public}@ - Got unexpected response code from get token request %@",
                               log: self.customLog, type: .debug, #function, String(httpResponse.statusCode))

                        if let extoleError = try? self.decoder.decode(ExtoleError.self, from: data) {
                            completion(nil, extoleError)
                        } else {
                            completion(nil, ExtoleError(message: "Could not decode JSON error message"))
                        }
                    }
                } else {
                    completion(nil, ExtoleError(message: "Could not decode JSON error message"))
                }
            } else {
                completion(nil, ExtoleError(message: "No data received from API request"))
            }
        }
        task.resume()
    }

    /**
     Deletes the access token which identifies this user.
     */
    public func deleteToken(completion: @escaping (ExtoleError?) -> Void) {
        let tokenUrlString = referralDomain + extoleApiUrls["token"]!
        let tokenUrl = URL(string: tokenUrlString)

        var request = URLRequest(url: tokenUrl!)
        request.httpMethod = "DELETE"
        if let accessToken = self.accessToken?.accessToken {
            os_log("%{public}@ - Have locally cached token as %@",
                   log: self.customLog, type: .debug, #function, accessToken)

            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        let cookieStore = HTTPCookieStorage.shared
        for cookie in cookieStore.cookies ?? [] where cookie.name == "access_token" {
            cookieStore.deleteCookie(cookie)
            os_log("%{public}@ - Deleting token from cookie store %@",
                   log: self.customLog, type: .debug, #function, cookie.name)
        }

        os_log("%{public}@ - Making DELETE request to URL %@", log: customLog,
               type: .debug, #function, tokenUrl?.absoluteString ?? "nil")
        let task = session.dataTask(with: request) { (data, response, _ error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    self.accessToken = nil
                    completion(nil)
                } else {
                    os_log("%{public}@ - Got unexpected response code from delete token request %@",
                           log: self.customLog, type: .debug, #function, String(httpResponse.statusCode))
                    if let data = data {
                        if let extoleError = try? self.decoder.decode(ExtoleError.self, from: data) {
                            completion(extoleError)
                        } else {
                            completion(ExtoleError(message: "Could not decode JSON error message"))
                        }
                    } else {
                        completion(ExtoleError(message: "Could not decode JSON error message"))
                    }
                }
            } else {
                completion(ExtoleError(message: "Did not get token response"))
            }

        }
        task.resume()
    }

    /**
     Retreives the current user from the API.
     
     - Parameters
        - completion: callback method which returns the user in the event of a success or an error
     */
    public func getMe(completion: @escaping (ExtolePerson?, ExtoleError?) -> Void) {
        self.getToken { (token, error) in
            if let token = token {
                let meUrlString = self.referralDomain + self.extoleApiUrls["me"]!
                let meUrl = URL(string: meUrlString)
                var request = URLRequest(url: meUrl!)

                os_log("%{public}@ - Calling with token %@", log: self.customLog,
                       type: .debug, #function, token.accessToken)
                request.setValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")

                os_log("%{public}@ - Making GET request to URL %@", log: self.customLog,
                       type: .debug, meUrl?.absoluteString ?? "nil")

                let task = self.session.dataTask(with: request) { (data, response, _ error) in
                    if let data = data {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                if let person = try? self.decoder.decode(ExtolePerson.self, from: data) {
                                    completion(person, nil)
                                } else {
                                    completion(nil, ExtoleError(message: "Could not decode JSON error"))
                                }
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

    /**
     Updates the value of Person at Extole.
     
     - Parameters
       - person: new values for person which will update if possible
       - completion: callback method which returns the user in the event of a success or an error
     */
    public func updateMe(person: ExtolePerson, completion: @escaping (ExtolePerson?, ExtoleError?) -> Void) {
        self.getToken { (token, error) in
            if let token = token {
                let meUrlString = self.referralDomain + self.extoleApiUrls["me"]!
                let meUrl = URL(string: meUrlString)
                var request = URLRequest(url: meUrl!)
                request.httpMethod = "POST"
                request.setValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                if let data = try? self.encoder.encode(person) {
                    os_log("%{public}@ - Making request to update person %@", log: self.customLog,
                           type: .debug, #function, String(data: data, encoding: .utf8)!)
                    request.httpBody = data
                }

                os_log("%{public}@ - Making POST request to URL %@", log: self.customLog,
                       type: .debug, #function, meUrl?.absoluteString ?? "nil")

                let task = self.session.dataTask(with: request) { (data, response, _ error) in
                    if let data = data {
                        let responseString = String(data: data, encoding: .utf8)
                        os_log("%{public}@ - Got response %@", log: self.customLog,
                               type: .debug, #function, responseString!)

                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 {
                                // 200 Response is success, return the person object
                                self.getMe(completion: { (person, error) in
                                    completion(person, error)
                                })
                            } else {
                                if let extoleError = try? self.decoder.decode(ExtoleError.self, from: data) {
                                    completion(nil, extoleError)
                                } else {
                                    completion(nil, ExtoleError(message: "Could not decode JSON error message"))
                                }
                            }
                        } else {
                            completion(nil, ExtoleError(message: "No status received from API request"))
                        }
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
}

/**
 An Extole Access Token represents access to a single user at Extole.
 */
public class ExtoleAccessToken: Codable, CustomStringConvertible {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")

    public var accessToken: String
    public var expiresIn: Int?
    public var scopes: [String]?
    public var capabilities: [String]?

    // Setup bindings from JSON to properties
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in" // TODO: date conversion
        case scopes
        case capabilities
    }

    public var description: String {
        return self.accessToken
    }

    /**
      Init from a String access token which can be useful if the consumers token is stored
      in local cache as part of creating the system.
    */
    public init(accessToken: String) {
        self.accessToken = accessToken
    }
}

public class ExtolePerson: Codable {
    let customLog = OSLog(subsystem: "com.extole", category: "extole_referral")

    public var personId: String?
    public var email: String?
    public var partnerUserId: String?
    public var firstName: String?
    public var lastName: String?
    public var profilePictureUrl: URL?

    // Setup bindings from JSON to properties
    // - TODO: cookie_consent,cookie_consent_type,processing_consent,processing_consent_type,parameters
    // {"id":"6646217761789432116","email":null,"first_name":null,"last_name":null,
    //  "profile_picture_url":null,"partner_user_id":null,"cookie_consent":null,
    //  "cookie_consent_type":null,"processing_consent":null,"processing_consent_type":null,
    //  "parameters":{}}

    enum CodingKeys: String, CodingKey {
        case personId = "id"
        case email
        case partnerUserId = "partner_user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case profilePictureUrl = "profile_picture_url"
    }

    init() {
    }
}

public class ExtoleError: Codable, CustomStringConvertible {
    public var uniqueId = "sdk" + UUID().uuidString
    public var httpStatusCode: Int?
    public var errorCode: String?
    public var message: String?
    public var description: String {
        return self.message ?? "no known error"
    }

    // Setup bindings from JSON to properties
    // TODO: Parameters
    enum CodingKeys: String, CodingKey {
        case uniqueId = "unique_id"
        case httpStatusCode = "http_status_code"
        case errorCode = "code"
        case message
    }

    init(message: String) {
        self.message = message
    }
}
