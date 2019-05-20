//
//  ConsentStringBuilderTests.swift
//  Consent String SDK SwiftTests
//
//  Created by Alexander Edge on 17/05/2019.
//  Copyright © 2019 Interactive Advertising Bureau. All rights reserved.
//

import XCTest
@testable import Consent_String_SDK_Swift

class ConsentStringBuilderTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testBuildConsentString() throws {

        let string = "BOMexSfOMexSfAAABAENAA////AAoAA"
        let padded = string.base64Padded
        let consentString = try ConsentString(consentString: string)
        let consentStringBuilder = ConsentStringBuilder(created: consentString.created, updated: consentString.updated, cmpIdentifier: consentString.cmpId, cmpVersion: consentString.cmpVersion, consentScreenID: consentString.consentScreen, consentLanguage: consentString.consentLanguage, vendorListVersion: consentString.vendorListVersion, maxVendorId: consentString.maxVendorId, vendorEncodingType: try consentString.encodingType(), allowedPurposes: Set(1...24), vendorsBitField: [], rangeEntries: [], defaultConsent: false)

        let builtString = try consentStringBuilder.build()

        let binaryString = binaryStringRepresenting(data: Data(base64Encoded: padded)!)
        XCTAssertTrue(binary(string: binaryString, isEqualToBinaryString: builtString))
    }

    func binaryStringRepresenting(data:Data) -> String {
        return  data.reduce("") { (acc, byte) -> String in
            let stringRep = String(byte, radix: 2)
            let pad = 8 - stringRep.count
            let padString = "".padding(toLength: pad, withPad: "0", startingAt: 0)
            return acc + padString + stringRep
        }
    }

    func binary(string:String, isEqualToBinaryString string2:String) -> Bool {
        if abs(string.count - string2.count) > 7 {
            return false
        }
        var index = 0
        var max = string.count
        if string.count > string2.count {
            max = string2.count
        }
        while index < max {
            if string[string.index(string.startIndex, offsetBy: index)] != string2[string2.index(string2.startIndex, offsetBy: index)] {
                return false
            }
            index += 1
        }
        if string.count > string2.count {
            while index < string.count {
                if string[string.index(string.startIndex, offsetBy: index)] != "0" {
                    return false
                }
                index += 1
            }
        } else {
            while index < string2.count {
                if string2[string2.index(string2.startIndex, offsetBy: index)] != "0" {
                    return false
                }
                index += 1
            }
        }
        return true
    }

}
