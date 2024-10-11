//
//  ParseTest.swift
//  
//
//  Created by Gereon Steffens on 03.05.23.
//

import Foundation
import Testing
@testable import modelgen

@Suite("Parse test")
struct ParseTest {
    private let json = """
    [
        {
            "status": "dog",
            "barks":true
        },
        {
            "status": "cat",
            "meows": false
        }
    ]
    """

    private let json2 = """
    [
        {
            "status": "dog",
            "barks":true
        },
        {
            "status": "cat",
            "meows": false
        },
        {
            "status": "pig",
            "oinks": true
        }
    ]
    """

    @Test("parse array")
    func testParseArray() throws {
        let animals = try JSONDecoder().decode([Animal].self, from: json.data(using: .utf8)!)
        #expect(animals.count == 2)
    }

    @Test("parse array failure")
    func testParseArrayFailure() throws {
        do {
            _ = try JSONDecoder().decode([Animal].self, from: json2.data(using: .utf8)!)
            Issue.record("decoding should fail")
        } catch DecodingError.typeMismatch {
            // expected
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("parse lossy array")
    func testParseLossyArray() throws {
        let animals = try JSONDecoder().decode(LossyDecodableArray<Animal>.self, from: json2.data(using: .utf8)!).elements
        #expect(animals.count == 2)
    }

}
