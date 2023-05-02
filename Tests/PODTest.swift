//
//  PODTest.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import XCTest
@testable import ModelGen

final class PODTest: XCTestCase {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "POD" : {
                    "type" : "object",
                    "required": [ "bool", "ints" ],
                    "properties" : {
                        "ref" : {
                            "$ref" : "#/components/schemas/Object"
                        },
                        "bool" : {
                            "type" : "boolean"
                        },
                        "ints" : {
                            "type" : "array",
                            "items" : {
                                "type" : "integer"
                            }
                        },
                        "lossy" : {
                            "type": "array",
                            "items": {
                                "$ref": "#/components/schemas/Foo"
                            }
                        },
                        "string" : {
                            "type" : "string"
                        },
                        "double" : {
                            "type" : "number"
                        }
                    }
                }
            }
        }
    }
    """

    private let expected = """
        public struct POD: Codable {
            public let bool: Bool

            public let double: Double?

            public let ints: [Int]

            public let lossy: [Foo]?

            public let ref: Object?

            public let string: String?

            public init(bool: Bool, double: Double?, ints: [Int], lossy: [Foo]?, ref: Object?, string: String?) {
                self.bool = bool
                self.double = double
                self.ints = ints
                self.lossy = lossy
                self.ref = ref
                self.string = string
            }

            enum CodingKeys: String, CodingKey {
                case bool = "bool"
                case double = "double"
                case ints = "ints"
                case lossy = "lossy"
                case ref = "ref"
                case string = "string"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.bool = try container.decode(Bool.self, forKey: .bool)
                self.double = try container.decodeIfPresent(Double.self, forKey: .double)
                self.ints = try container.decode([Int].self, forKey: .ints)
                self.lossy = try container.decodeIfPresent(LossyDecodableArray<Foo>.self, forKey: .lossy)?.elements
                self.ref = try container.decodeIfPresent(Object.self, forKey: .ref)
                self.string = try container.decodeIfPresent(String.self, forKey: .string)
            }
        }
        """

    func testPOD() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        generator.generate(modelName: "POD", skipHeader: true)
        let output = String(generator.buffer.dropLast(1))
        XCTAssertEqual(output, multiline: expected)
    }

}
