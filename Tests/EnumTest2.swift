//
//  File.swift
//  
//
//  Created by Gereon Steffens on 19.06.24.
//

import CustomDump
@testable import modelgen
import XCTest

final class EnumTest2: XCTestCase {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "Enum" : {
                    "type" : "object",
                    "required": [ "bool", "ints" ],
                    "properties" : {
                        "bEnum" : {
                            "type" : "string",
                            "enum" : [ "foo", "bar", "baz" ]
                        },
                        "aEnum" : {
                            "type" : "string",
                            "enum" : [ "plugh", "xyzzy" ]
                        }
                    }
                }
            }
        }
    }
    """

    private let expected = """
    """

    func testEnumOrder() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        generator.generate(modelName: "Enum", skipHeader: true)
        XCTAssertNoDifference(String(generator.buffer.dropLast(1)), expected)
    }
}
