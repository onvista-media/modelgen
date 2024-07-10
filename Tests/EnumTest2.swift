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
    public struct Enum: Codable {
        public let aEnum: AEnum?

        public let bEnum: BEnum?

        public init(aEnum: AEnum?, bEnum: BEnum?) {
            self.aEnum = aEnum
            self.bEnum = bEnum
        }

        enum CodingKeys: String, CodingKey {
            case aEnum = "aEnum"
            case bEnum = "bEnum"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.aEnum = try container.decodeIfPresent(AEnum.self, forKey: .aEnum)
            self.bEnum = try container.decodeIfPresent(BEnum.self, forKey: .bEnum)
        }

        public enum AEnum: String, Codable, CaseIterable, UnknownCaseRepresentable {
            case plugh = "plugh"
            case xyzzy = "xyzzy"

            case _unknownCase
            public static let unknownCase = Self._unknownCase

            public static func make() -> Self {
                ._unknownCase
            }
        }

        public enum BEnum: String, Codable, CaseIterable, UnknownCaseRepresentable {
            case bar = "bar"
            case baz = "baz"
            case foo = "foo"

            case _unknownCase
            public static let unknownCase = Self._unknownCase

            public static func make() -> Self {
                ._unknownCase
            }
        }

        public static func make(aEnum: AEnum? = nil, bEnum: BEnum? = nil) -> Self {
            self.init(aEnum: aEnum, bEnum: bEnum)
        }
    }
    """

    func testEnumOrder() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        generator.generate(modelName: "Enum", skipHeader: true)
        XCTAssertNoDifference(String(generator.buffer.dropLast(1)), expected)
    }
}
