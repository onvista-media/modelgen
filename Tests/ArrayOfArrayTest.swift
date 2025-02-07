//
//  ArrayOfArrayTest.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

// test 2d array items
@Suite("Array of Array test")
struct ArrayOfArrayTest {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "Parent" : {
                    "required" : [ "type" ],
                    "type" : "object",
                    "properties" : {
                        "type" : {
                            "type": "string"
                        }
                    },
                    "discriminator" : {
                        "propertyName" : "type",
                        "mapping" : {
                            "table" : "#/components/schemas/ArrayItem"
                        }
                    }
                },
                "ArrayItem" : {
                    "required" : [ "type" ],
                    "type" : "object",
                    "description" : "Table",
                    "allOf" : [
                        {
                            "$ref" : "#/components/schemas/Parent"
                        },
                        {
                            "type" : "object",
                            "properties" : {
                                "headlineType" : {
                                    "type" : "string"
                                },
                                "rows" : {
                                    "type" : "array",
                                    "items" : {
                                        "type" : "array",
                                        "items" : {
                                            "type" : "string",
                                        }
                                    }
                                }
                            }
                        }
                    ]
                }
            }
        }
    }
    """

    private let expectedResult =
#"""
public struct ArrayItem: Codable {
    // MARK: - inherited properties from Parent
    public let type: String

    // MARK: - ArrayItem properties
    public let headlineType: String?

    public let rows: [[String]]?

    public init(type: String, headlineType: String?, rows: [[String]]?) {
        // MARK: - inherited properties from Parent
        self.type = type
        // MARK: - ArrayItem properties
        self.headlineType = headlineType
        self.rows = rows
    }

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case headlineType = "headlineType"
        case rows = "rows"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.headlineType = try container.decodeIfPresent(String.self, forKey: .headlineType)
        self.rows = try container.decodeIfPresent([[String]].self, forKey: .rows)
    }

    public static func make(type: String = "", headlineType: String? = nil, rows: [[String]]? = nil) -> Self {
        self.init(type: type, headlineType: headlineType, rows: rows)
    }
}

extension ArrayItem: ParentProtocol {}
"""#

    @Test("child class table")
    func testChildClassTable() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "ArrayItem")

        expectNoDifference(String(generator.buffer.dropLast(1)), expectedResult)
    }
}
