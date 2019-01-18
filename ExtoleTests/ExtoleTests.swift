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

    /*
    func testMeEmpty() {
        let testexpectation = expectation(description: "ExtoleService will return a Person Dictionary")

        extole!.getMe() { (person) in
            if let person = person {
                print("Person!")
            } else {
                print("Not Person")
            }
            testexpectation.fulfill()
        }
        
        waitForExpectations(timeout:3) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
   */
}
