//
//  ConsentStringBuilder.swift
//  Consent String SDK Swift
//
//  Created by Alexander Edge on 17/05/2019.
//  Copyright © 2019 Interactive Advertising Bureau. All rights reserved.
//

import Foundation

public struct ConsentStringBuilder {

    enum Error: Swift.Error {
        case invalidLanguageCode
    }

    let version: Int = 1
    
    /// Epoch deciseconds when record was created
    let created: Date

    /// Epoch deciseconds when consent string was last updated
    let updated: Date

    /// Consent Manager Provider ID that last updated the consent string
    let cmpId: Int

    /// Consent Manager Provider version
    let cmpVersion: Int

    /// Screen number in the CMP where consent was given
    let consentScreenId: Int

    /// Two-letter ISO639-1 language code that CMP asked for consent in
    let consentLanguage: String

    /// Set of allowed purposes
    let allowedPurposes: Set<Int>

    /// Version of vendor list used in most recent consent string update
    let vendorListVersion: Int

    /// The maximum VendorId for which consent values are given.
    let maxVendorId: Int

    let defaultConsent: Bool

    /// Set of allowed vendor IDs
    let allowedVendorIds: Set<Int>

    init(created: Date = Date(), updated: Date = Date(), cmpId: Int, cmpVersion: Int, consentScreenId: Int, consentLanguage: String, allowedPurposes: Set<Int>, vendorListVersion: Int, maxVendorId: Int, defaultConsent: Bool, allowedVendorIds: Set<Int>) {
        self.created = created
        self.updated = updated
        self.cmpId = cmpId
        self.cmpVersion = cmpVersion
        self.consentScreenId = consentScreenId
        self.consentLanguage = consentLanguage
        self.allowedPurposes = allowedPurposes
        self.vendorListVersion = vendorListVersion
        self.maxVendorId = maxVendorId
        self.defaultConsent = defaultConsent
        self.allowedVendorIds = allowedVendorIds
    }

    public func build() throws -> String {
        let commonBinaryString = try commonConsentBinaryString()
        // we encode by both methods (bit field and ranges) and use whichever is smallest
        let encodingUsingBitField = convertBinaryStringToTrimmedBase64String(padStringToNearestByte(commonBinaryString + bitFieldBinaryString))
        let encodingUsingRanges = convertBinaryStringToTrimmedBase64String(padStringToNearestByte(commonBinaryString + rangesBinaryString))
        if encodingUsingBitField.count < encodingUsingRanges.count {
            return encodingUsingBitField
        } else {
            return encodingUsingRanges
        }
    }

    func commonConsentBinaryString() throws -> String {
        var consentString = ""
        consentString.append(encode(integer: version, toLength: Constants.version.length))
        consentString.append(encode(date: created, toLength: Constants.created.length))
        consentString.append(encode(date: updated, toLength: Constants.updated.length))
        consentString.append(encode(integer: cmpId, toLength: Constants.cmpIdentifier.length))
        consentString.append(encode(integer: cmpVersion, toLength: Constants.cmpVersion.length))
        consentString.append(encode(integer: consentScreenId, toLength: Constants.consentScreen.length))

        guard let firstLanguageCharacter = consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 0)].asciiValue,
            let secondLanguageCharacter = consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 1)].asciiValue else {
            throw Error.invalidLanguageCode
        }

        consentString.append(encode(integer: Int(firstLanguageCharacter - 65), toLength: Constants.consentLanguage.length / 2))
        consentString.append(encode(integer: Int(secondLanguageCharacter - 65), toLength: Constants.consentLanguage.length / 2))
        consentString.append(encode(integer: vendorListVersion, toLength: Constants.vendorListVersion.length))
        consentString.append(encode(purposeBitFieldForPurposes: allowedPurposes))
        consentString.append(encode(integer: maxVendorId, toLength: Constants.maxVendorIdentifier.length))
        return consentString
    }

    var bitFieldBinaryString: String {
        var consentString = ""
        consentString.append(encode(integer: VendorEncodingType.bitField.rawValue, toLength: Constants.encodingType.length))
        consentString.append(encode(vendorBitFieldForVendors: allowedVendorIds, maxVendorId: maxVendorId))
        return consentString
    }

    var rangesBinaryString: String {
        var consentString = ""
        consentString.append(encode(integer: VendorEncodingType.range.rawValue, toLength: Constants.encodingType.length))
        consentString.append(encode(integer: defaultConsent ? 1 : 0, toLength: Constants.defaultConsent.length))
        consentString.append(encode(vendorRanges: ranges(for: allowedVendorIds, in: Set(1...maxVendorId), defaultConsent: defaultConsent)))
        return consentString
    }

    func convertBinaryStringToTrimmedBase64String(_ string: String) -> String {
        let data = Data(bytes: string.split(by: 8).compactMap { UInt8($0, radix: 2) })
        return data.base64EncodedString().trimmingCharacters(in: ["="])
    }

    func padStringToNearestByte(_ string: String) -> String {
        let (byteCount, bitRemainder) = string.count.quotientAndRemainder(dividingBy: 8)
        let totalBytes = byteCount + (bitRemainder > 0 ? 1 : 0)
        return string.padRight(toLength: totalBytes * 8)
    }

    func encode(integer: Int, toLength length: Int) -> String {
        return String(integer, radix: 2).padLeft(toLength: length)
    }

    func encode(date: Date, toLength length: Int) -> String {
        return encode(integer: Int(date.timeIntervalSince1970 * 1000 / 100), toLength: length)
    }

    func encode(purposeBitFieldForPurposes purposes: Set<Int>) -> String {
        return (0..<Constants.purposes.length).reduce("") { $0 + (purposes.contains($1 + 1) ? "1" : "0") }
    }

    func encode(vendorBitFieldForVendors vendors: Set<Int>, maxVendorId: Int) -> String {
        return (1...maxVendorId).reduce("") { $0 + (vendors.contains($1) ? "1" : "0") }
    }

    func encode(vendorRanges ranges: [ClosedRange<Int>]) -> String {
        var string = ""
        string.append(encode(integer: ranges.count, toLength: Constants.numberOfEntries.length))
        for range in ranges {
            if range.count == 1 {
                // single entry
                string.append(encode(integer: 0, toLength: 1))
                string.append(encode(integer: range.lowerBound, toLength: Constants.vendorIdentifierSize))
            } else {
                // range entry
                string.append(encode(integer: 1, toLength: 1))
                string.append(encode(integer: range.lowerBound, toLength: Constants.vendorIdentifierSize))
                string.append(encode(integer: range.upperBound, toLength: Constants.vendorIdentifierSize))
            }
        }
        return string
    }

    func ranges(for allowedVendorIds: Set<Int>, in allVendorIds: Set<Int>, defaultConsent: Bool) -> [ClosedRange<Int>] {
        let vendorsToEncode = defaultConsent ? allVendorIds.subtracting(allowedVendorIds).sorted() : allowedVendorIds.sorted()

        var ranges = [ClosedRange<Int>]()
        var currentRangeStart: Int?
        for vendorId in allVendorIds.sorted() {
            if vendorsToEncode.contains(vendorId) {
                if currentRangeStart == nil {
                    // start a new range
                    currentRangeStart = vendorId
                }
            } else if let rangeStart = currentRangeStart {
                // close the range
                ranges.append(rangeStart...vendorId-1)
                currentRangeStart = nil
            }
        }

        // close any range open at the end
        if let rangeStart = currentRangeStart, let last = vendorsToEncode.last {
            ranges.append(rangeStart...last)
            currentRangeStart = nil
        }
        return ranges
    }

}

extension String {
    func padLeft(withCharacter character: String = "0", toLength length: Int) -> String {
        let padCount = length - count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }

    func padRight(withCharacter character: String = "0", toLength length: Int) -> String {
        let padCount = length - count
        guard padCount > 0 else { return self }
        return self + String(repeating: character, count: padCount)
    }
}

extension String {
    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()

        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }
}

extension ConsentString {

    convenience init(created: Date, updated: Date, cmpId: Int, cmpVersion: Int, consentScreenId: Int, consentLanguage: String, allowedPurposes: Set<Int>, vendorListVersion: Int, maxVendorId: Int, allowedVendorIds: Set<Int>) throws {
        let builder = ConsentStringBuilder(created: created,
                                           updated: updated, 
                                           cmpId: cmpId,
                                           cmpVersion: cmpVersion,
                                           consentScreenId: consentScreenId,
                                           consentLanguage: consentLanguage,
                                           allowedPurposes: allowedPurposes,
                                           vendorListVersion: vendorListVersion,
                                           maxVendorId: maxVendorId,
                                           defaultConsent: false,
                                           allowedVendorIds: allowedVendorIds)
        try self.init(consentString: try builder.build())
    }

}
