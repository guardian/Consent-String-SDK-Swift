//
//  ConsentStringBuilder.swift
//  Consent String SDK Swift
//
//  Created by Alexander Edge on 17/05/2019.
//  Copyright © 2019 Interactive Advertising Bureau. All rights reserved.
//

import Foundation

public struct ConsentStringBuilder {

    /// Epoch deciseconds when record was created
    let created: Date

    /// Epoch deciseconds when consent string was last updated
    let updated: Date

    /// Consent Manager Provider ID that last updated the consent string
    let cmpIdentifier: Int

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

    public func build() throws -> String {
        let bitField = try buildUsingBitField()
        let ranges = try buildUsingRanges()
        if bitField.count < ranges.count {
            return bitField
        } else {
            return ranges
        }
    }

    func buildUsingBitField() throws -> String {
        var consentString = ""
        consentString.append(String(1, radix: 2).padLeft(toLength: Constants.version.length))
        consentString.append(String(Int(created.timeIntervalSince1970 * 1000 / 100), radix: 2).padLeft(toLength: Constants.created.length))
        consentString.append(String(Int(updated.timeIntervalSince1970 * 1000 / 100), radix: 2).padLeft(toLength: Constants.updated.length))
        consentString.append(String(cmpIdentifier, radix: 2).padLeft(toLength: Constants.cmpIdentifier.length))
        consentString.append(String(cmpVersion, radix: 2).padLeft(toLength: Constants.cmpVersion.length))
        consentString.append(String(consentScreenId, radix: 2).padLeft(toLength: Constants.consentScreen.length))

        let language = String(consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 0)].asciiValue! - 65, radix: 2).padLeft(toLength: 6) + String(consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 1)].asciiValue! - 65, radix: 2).padLeft(toLength: 6)
        consentString.append(language)
        consentString.append(String(vendorListVersion, radix: 2).padLeft(toLength: Constants.vendorListVersion.length))
        consentString.append(encodePurposeBitField(for: allowedPurposes))
        consentString.append(String(maxVendorId, radix: 2).padLeft(toLength: Constants.maxVendorIdentifier.length))
        consentString.append(String(VendorEncodingType.bitField.rawValue, radix: 2).padLeft(toLength: Constants.encodingType.length))
        consentString.append(encodeVendorBitField(for: allowedVendorIds, maxVendorId: maxVendorId))

        // pad the string to a byte boundary
        let (byteCount, bitRemainder) = consentString.count.quotientAndRemainder(dividingBy: 8)
        let totalBytes = byteCount + (bitRemainder > 0 ? 1 : 0)
        let binaryString = consentString.padRight(toLength: totalBytes * 8)

        // convert the string representation into data
        let data = Data(bytes: binaryString.split(by: 8).compactMap { UInt8($0, radix: 2) })
        return data.base64EncodedString()
    }

    func buildUsingRanges() throws -> String {
        var consentString = ""
        consentString.append(String(1, radix: 2).padLeft(toLength: Constants.version.length))
        consentString.append(String(Int(created.timeIntervalSince1970 * 1000 / 100), radix: 2).padLeft(toLength: Constants.created.length))
        consentString.append(String(Int(updated.timeIntervalSince1970 * 1000 / 100), radix: 2).padLeft(toLength: Constants.updated.length))
        consentString.append(String(cmpIdentifier, radix: 2).padLeft(toLength: Constants.cmpIdentifier.length))
        consentString.append(String(cmpVersion, radix: 2).padLeft(toLength: Constants.cmpVersion.length))
        consentString.append(String(consentScreenId, radix: 2).padLeft(toLength: Constants.consentScreen.length))

        let language = String(consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 0)].asciiValue! - 65, radix: 2).padLeft(toLength: 6) + String(consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 1)].asciiValue! - 65, radix: 2).padLeft(toLength: 6)
        consentString.append(language)
        consentString.append(String(vendorListVersion, radix: 2).padLeft(toLength: Constants.vendorListVersion.length))
        consentString.append(encodePurposeBitField(for: allowedPurposes))
        consentString.append(String(maxVendorId, radix: 2).padLeft(toLength: Constants.maxVendorIdentifier.length))
        consentString.append(String(VendorEncodingType.range.rawValue, radix: 2).padLeft(toLength: Constants.encodingType.length))
        consentString.append((defaultConsent ? "1" : "0").padLeft(toLength: Constants.defaultConsent.length))

        let ranges = self.ranges(for: allowedVendorIds, in: Set(1...maxVendorId), defaultConsent: defaultConsent)
        consentString.append(encode(ranges))

        // pad the string to a byte boundary
        let (byteCount, bitRemainder) = consentString.count.quotientAndRemainder(dividingBy: 8)
        let totalBytes = byteCount + (bitRemainder > 0 ? 1 : 0)
        let binaryString = consentString.padRight(toLength: totalBytes * 8)

        // convert the string representation into data
        let data = Data(bytes: binaryString.split(by: 8).compactMap { UInt8($0, radix: 2) })
        return data.base64EncodedString()
    }

    func encodePurposeBitField(for purposes: Set<Int>) -> String {
        return (0..<Constants.purposes.length).reduce("") { $0 + (purposes.contains($1 + 1) ? "1" : "0") }
    }

    func encodeVendorBitField(for vendors: Set<Int>, maxVendorId: Int) -> String {
        return (1...maxVendorId).reduce("") { $0 + (vendors.contains($1) ? "1" : "0") }
    }

    func encode(_ ranges: [ClosedRange<Int>]) -> String {
        var string = ""
        string.append(String(ranges.count, radix: 2).padLeft(toLength: Constants.numberOfEntries.length))
        for range in ranges {
            if range.count == 1 {
                // single entry
                string.append("0")
                string.append(String(range.lowerBound, radix: 2).padLeft(toLength: Constants.vendorIdentifierSize))
            } else {
                // range entry
                string.append("1")
                string.append(String(range.lowerBound, radix: 2).padLeft(toLength: Constants.vendorIdentifierSize))
                string.append(String(range.upperBound, radix: 2).padLeft(toLength: Constants.vendorIdentifierSize))
            }
        }
        return string
    }

    func ranges(for allowedVendorIds: Set<Int>, in vendorIds: Set<Int>, defaultConsent: Bool) -> [ClosedRange<Int>] {
        let vendorIds = defaultConsent ? vendorIds.subtracting(allowedVendorIds).sorted() : allowedVendorIds.sorted()

        var ranges = [ClosedRange<Int>]()
        var currentRangeStart: Int?
        for vendorId in vendorIds {
            if vendorIds.contains(vendorId) {
                if currentRangeStart == nil {
                    // start a new range
                    currentRangeStart = vendorId
                }
            } else if let rangeStart = currentRangeStart {
                // close the range
                ranges.append(rangeStart...vendorId)
                currentRangeStart = nil
            }
        }

        // close any range open at the end
        if let rangeStart = currentRangeStart, let last = vendorIds.last {
            ranges.append(rangeStart...last)
            currentRangeStart = nil
        }
        return ranges
    }

}

extension String {
    func padLeft(with character: String = "0", toLength length: Int) -> String {
        //return padding(toLength: length, withPad: character, startingAt: 0)
        let padCount = length - count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }

    func padRight(with character: String = "0", toLength length: Int) -> String {
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
