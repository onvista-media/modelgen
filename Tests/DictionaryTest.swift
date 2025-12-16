//
//  DictionaryTest.swift
//
//  Copyright © 2025 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

@Suite("Dictionary test")
struct DictionaryTest {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "Dictionary" : {
                    "type" : "object",
                    "required": [ "redirectUri", "inlineMessage", "errors" ],
                    "properties" : {
                        "redirectUri" : {
                            "type" : "string"
                        },
                        "inlineMessage" : {
                            "type" : "string"
                        },
                        "errors" : {
                            "type" : "array",
                            "items" : {
                                "type" : "object",
                                "additionalProperties" : {
                                    "type" : "string"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    """

    private let expected = """
        public struct Dictionary: Codable {
            public let errors: [[String: String]]

            public let inlineMessage: String

            public let redirectUri: String

            public init(errors: [[String: String]], inlineMessage: String, redirectUri: String) {
                self.errors = errors
                self.inlineMessage = inlineMessage
                self.redirectUri = redirectUri
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.errors = try container.decode([[String: String]].self, forKey: .errors)
                self.inlineMessage = try container.decode(String.self, forKey: .inlineMessage)
                self.redirectUri = try container.decode(String.self, forKey: .redirectUri)
            }

            public static func make(errors: [[String: String]] = [], inlineMessage: String = "", redirectUri: String = "") -> Self {
                self.init(errors: errors, inlineMessage: inlineMessage, redirectUri: redirectUri)
            }
        }
        """

    @Test("test dictionary")
    func testDictionary() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "Dictionary")
        let output = String(generator.buffer.dropLast(1))
        expectNoDifference(output, expected)
    }
}
