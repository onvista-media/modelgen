//
//  EnumTest.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import XCTest
@testable import ModelGen

final class EnumTest: XCTestCase {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "Enum" : {
                    "type" : "string",
                    "enum" : [ "CASE1", "2CASE", "PUBLIC", "TEST_SNAKE_CASE" ]
                },
            }
        }
    }
    """

    private let expected = """
    public enum Enum: String, Codable, CaseIterable, UnknownCaseRepresentable {
        case case1 = "CASE1"
        case _2case = "2CASE"
        case _public = "PUBLIC"
        case testSnakeCase = "TEST_SNAKE_CASE"

        case _unknownCase
        public static let unknownCase = Self._unknownCase
    }
    """

    func testEnum() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        generator.generate(modelName: "Enum", skipHeader: true)
        XCTAssertEqual(String(generator.buffer.dropLast(1)), multiline: expected)
    }

}
