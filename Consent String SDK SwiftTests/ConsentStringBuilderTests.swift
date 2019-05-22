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

    var builder: ConsentStringBuilder!

    override func setUp() {
        super.setUp()
        builder = ConsentStringBuilder()
    }

    override func tearDown() {
        builder = nil
        super.tearDown()
    }

    func testEncodingInt() {
        XCTAssertEqual(builder.encode(integer: 1, toLength: NSRange.version.length), "000001")
    }

    func testEncodingDate() {
        let date = Date(timeIntervalSince1970: 1510082155.4)
        XCTAssertEqual(builder.encode(date: date, toLength: NSRange.updated.length), "001110000100000101000100000000110010")
    }

    func testEncodingBitfield() {
        XCTAssertEqual(builder.encode(vendorBitFieldForVendors: [2,4,6,8,10,12,14,16,18,20], maxVendorId: 20), "01010101010101010101")
    }

    func testEncodingNoVendorRanges() {
        XCTAssertEqual(builder.encode(vendorRanges: []), "000000000000")
    }

    func testEncodingSingleVendorIdRange() {
        XCTAssertEqual(builder.encode(vendorRanges: [9...9]), "00000000000100000000000001001")
    }

    func testEncodingMultipleVendorIdRange() {
        XCTAssertEqual(builder.encode(vendorRanges: [1...3]), "000000000001100000000000000010000000000000011")
    }

    func testEncodingMixedVendorRanges() {
        XCTAssertEqual(builder.encode(vendorRanges: [1...3, 9...9]), "00000000001010000000000000001000000000000001100000000000001001")
    }

    func testUsesRangesOverBitField() throws {
        XCTAssertEqual(try builder.build(created: Date(timeIntervalSince1970: 1510082155.4), updated: Date(timeIntervalSince1970: 1510082155.4), cmpId: 7, cmpVersion: 1, consentScreenId: 3, consentLanguage: "EN", allowedPurposes: [.storageAndAccess, .personalization, .adSelection], vendorListVersion: 8, maxVendorId: 2011, defaultConsent: true, allowedVendorIds: Set<VendorIdentifier>(1...2011).subtracting([9])), "BOEFEAyOEFEAyAHABDENAI4AAAB9vABAASA")
    }

    func testUsesBitFieldOverRanges() throws {
        let vendorIds = ClosedRange<VendorIdentifier>(1...234).compactMap { $0.isMultiple(of: 2) ? nil : $0 }
         XCTAssertEqual(try builder.build(created: Date(timeIntervalSince1970: 1510082155.4), updated: Date(timeIntervalSince1970: 1510082155.4), cmpId: 7, cmpVersion: 1, consentScreenId: 3, consentLanguage: "EN", allowedPurposes: [.storageAndAccess, .personalization, .adSelection], vendorListVersion: 8, maxVendorId: 2011, defaultConsent: true, allowedVendorIds: Set(vendorIds)), "BOEFEAyOEFEAyAHABDENAI4AAAB9tVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
    }
}
