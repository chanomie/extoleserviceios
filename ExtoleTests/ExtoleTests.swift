//
//  ExtoleTests.swift
//  ExtoleTests
//
//  Created by Jordan Reed on 1/12/19.
//  Copyright © 2019 Extole, Inc. All rights reserved.
//

import XCTest
@testable import Extole

class ExtoleTests: XCTestCase {
    var extole : ExtoleService?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        extole = ExtoleService(referralDomain: "https://refer-jordan.extole.com")
        extole?.deleteToken(completion: { (error) in    
        })
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetToken() {
        let testexpectation = expectation(description: "ExtoleService will return a Access Token")
            
        extole!.getToken() { (token, error) in
            XCTAssertNotNil(token, "Returned access token should have value")
            XCTAssertNil(error, "Returned error should be empty")
            
            print("Received token: ", token?.accessToken ?? "failed")
            testexpectation.fulfill()
        }
        
        waitForExpectations(timeout:3) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testGetTokenInvalidUrlFromExtole() {
        let testexpectation = expectation(description: "ExtoleService will return a Access Token")
        let extoleInvalid = ExtoleService(referralDomain: "https://refer-badness.extole.com")
        
        extoleInvalid.getToken() { (token, error) in
            XCTAssertNil(token, "Returned access token should be nil")
            XCTAssertNotNil(error, "Returned error token should be nil")
            print("Received token: ", token?.accessToken ?? "failed")
            testexpectation.fulfill()
        }
        
        waitForExpectations(timeout:3) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testGetMe() {
        let testexpectation = expectation(description: "ExtoleService will return a Person")
        
        extole?.getMe(completion: { (person, error) in
            XCTAssertNotNil(person, "Returned person should have value")
            XCTAssertNil(error, "Returned error should be empty")
            
            testexpectation.fulfill()
        })
        
        waitForExpectations(timeout:3) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testUpdateMe() {
        let testexpectation = expectation(description: "ExtoleService will return a Person")
        let person = ExtolePerson()
        person.email="testemail" + UUID().uuidString + "@example.com"
        
        extole?.updateMe(person: person, completion: { (personResponse, error) in
            XCTAssertNotNil(personResponse, "Returned person should have value")
            XCTAssertNil(error, "Returned error should be empty")
            
            testexpectation.fulfill()
        })
        
        waitForExpectations(timeout:10) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }

    }
}
