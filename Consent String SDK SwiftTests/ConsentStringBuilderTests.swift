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

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testEncodingInt() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        XCTAssertEqual(builder.encode(integer: 1, toLength: Constants.version.length), "000001")
    }

    func testEncodingDate() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        let date = Date(timeIntervalSince1970: 1510082155.4)
        XCTAssertEqual(builder.encode(date: date, toLength: Constants.updated.length), "001110000100000101000100000000110010")
    }

    func testEncodingBitfield() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        XCTAssertEqual(builder.encode(vendorBitFieldForVendors: [2,4,6,8,10,12,14,16,18,20], maxVendorId: 20), "01010101010101010101")
    }

    func testEncodingNoVendorRanges() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        XCTAssertEqual(builder.encode(vendorRanges: []), "000000000000")
    }

    func testEncodingSingleVendorIdRange() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        XCTAssertEqual(builder.encode(vendorRanges: [9...9]), "00000000000100000000000001001")
    }

    func testEncodingMultipleVendorIdRange() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        XCTAssertEqual(builder.encode(vendorRanges: [1...3]), "000000000001100000000000000010000000000000011")
    }

    func testEncodingMixedVendorRanges() {
        let builder = ConsentStringBuilder(cmpId: 0, cmpVersion: 0, consentScreenId: 0, consentLanguage: "EN", allowedPurposes: [], vendorListVersion: 0, maxVendorId: 2011, defaultConsent: false, allowedVendorIds: [])
        XCTAssertEqual(builder.encode(vendorRanges: [1...3, 9...9]), "00000000001010000000000000001000000000000001100000000000001001")
    }

    func testUsesRangesOverBitField() throws {
        let builder = ConsentStringBuilder(created: Date(timeIntervalSince1970: 1510082155.4), updated: Date(timeIntervalSince1970: 1510082155.4), cmpId: 7, cmpVersion: 1, consentScreenId: 3, consentLanguage: "EN", allowedPurposes: [1,2,3], vendorListVersion: 8, maxVendorId: 2011, defaultConsent: true, allowedVendorIds: Set(1...2011).subtracting([9]))
        XCTAssertEqual(try builder.build(), "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASA")
    }

    func testUsesBitFieldOverRanges() throws {
        let vendorIds = (1...234).compactMap { $0.isMultiple(of: 2) ? nil : $0 }
        let builder = ConsentStringBuilder(created: Date(timeIntervalSince1970: 1510082155.4), updated: Date(timeIntervalSince1970: 1510082155.4), cmpId: 7, cmpVersion: 1, consentScreenId: 3, consentLanguage: "EN", allowedPurposes: [1,2,3], vendorListVersion: 8, maxVendorId: 2011, defaultConsent: true, allowedVendorIds: Set(vendorIds))
         XCTAssertEqual(try builder.build(), "BOEFEAyOEFEAyAHABDENAI4AAAB9tVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
    }
}
