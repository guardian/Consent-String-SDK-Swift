//
//  ConsentStringBuilderTests.swift
//  Consent String SDK SwiftTests
//
//  Created by Alexander Edge on 17/05/2019.
//  Copyright © 2019 Interactive Advertising Bureau. All rights reserved.
//

import XCTest
@testable import Consent_String_SDK_Swift

class ConsentStringBuilderTests: XCTestCase, BinaryStringTestSupport {

    func testBuildConsentString() throws {
        let string = "BOM03lPOM03lPAAABAENAAAAAAAChAAAAAAI"
        let padded = string.base64Padded
        let consentString = try ConsentString(consentString: string)
        let consentStringBuilder = ConsentStringBuilder(created: consentString.created, updated: consentString.updated, cmpIdentifier: consentString.cmpId, cmpVersion: consentString.cmpVersion, consentScreenId: consentString.consentScreen, consentLanguage: consentString.consentLanguage, allowedPurposes: Set(consentString.purposesAllowed.map(Int.init)), vendorListVersion: consentString.vendorListVersion, maxVendorId: consentString.maxVendorId, defaultConsent: consentString.defaultConsent, allowedVendorIds: Set(consentString.allowedVendorIds.map(Int.init)))
        let binaryString = binaryStringRepresenting(data: Data(base64Encoded: padded)!)
        print(binaryString)
        XCTAssertEqual(padded, try consentStringBuilder.build())
    }

    func testBuildConsentStringWithRange() throws {
        let string = "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASA"
        let padded = string.base64Padded
        let consentString = try ConsentString(consentString: string)
        let consentStringBuilder = ConsentStringBuilder(created: consentString.created, updated: consentString.updated, cmpIdentifier: consentString.cmpId, cmpVersion: consentString.cmpVersion, consentScreenId: consentString.consentScreen, consentLanguage: consentString.consentLanguage, allowedPurposes: Set(consentString.purposesAllowed.map(Int.init)), vendorListVersion: consentString.vendorListVersion, maxVendorId: consentString.maxVendorId, defaultConsent: consentString.defaultConsent, allowedVendorIds: Set(consentString.allowedVendorIds.map(Int.init)))
        let binaryString = binaryStringRepresenting(data: Data(base64Encoded: padded)!)
        print(binaryString)
        XCTAssertEqual(padded, try consentStringBuilder.build())
    }

}
