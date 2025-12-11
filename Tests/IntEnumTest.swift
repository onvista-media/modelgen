//
//  IntEnumTest.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

@Suite("IntEnum test")
struct IntEnumTest {
    private let spec = """
     {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "IntEnum" : {
                    "type" : "integer",
                    "description" : "...",
                    "format" : "int64",
                    "enum" : [ 1, 2, 3, 4, 5, 6, 7, 8, 21, 22 ]
                },
            }
        }
    }
    """

    private let expected = """
    public typealias IntEnum = Int
    """

    @Test("IntEnum")
    func testIntEnum() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "IntEnum")
        expectNoDifference(String(generator.buffer.dropLast(1)), expected)
    }
}
