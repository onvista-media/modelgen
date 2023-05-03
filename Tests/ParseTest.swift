//
//  ParseTest.swift
//  
//
//  Created by Gereon Steffens on 03.05.23.
//

import XCTest
@testable import modelgen

final class ParseTest: XCTestCase {
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

    func testParseArray() throws {
        let animals = try JSONDecoder().decode([Animal].self, from: json.data(using: .utf8)!)
        XCTAssertEqual(animals.count, 2)
    }

    func testParseArrayFailure() throws {
        do {
            _ = try JSONDecoder().decode([Animal].self, from: json2.data(using: .utf8)!)
            XCTFail("decoding should fail")
        } catch DecodingError.typeMismatch {
            // expected
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testParseLossyArray() throws {
        let animals = try JSONDecoder().decode(LossyDecodableArray<Animal>.self, from: json2.data(using: .utf8)!).elements
        XCTAssertEqual(animals.count, 2)
    }

}
