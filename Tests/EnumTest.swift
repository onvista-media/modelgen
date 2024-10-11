//
//  EnumTest.swift
//  
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import CustomDump
import XCTest
@testable import modelgen

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
        case _2case = "2CASE"
        case case1 = "CASE1"
        case _public = "PUBLIC"
        case testSnakeCase = "TEST_SNAKE_CASE"

        case _unknownCase
        public static let unknownCase = Self._unknownCase

        public static func make() -> Self {
            ._unknownCase
        }
    }
    """

    func testEnum() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        generator.generate(modelName: "Enum")
        XCTAssertNoDifference(String(generator.buffer.dropLast(1)), expected)
    }

}
