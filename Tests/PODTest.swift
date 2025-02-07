//
//  PODTest.swift
//  
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

@Suite("POD test")
struct PODTest {
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
                        },
                        "foobar" : {
                            "type" : "string",
                            "enum" : [ "foo", "bar", "baz" ]
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

            public let foobar: Foobar?

            public let ints: [Int]

            public let lossy: [Foo]?

            public let ref: Object?

            public let string: String?

            public init(bool: Bool, double: Double?, foobar: Foobar?, ints: [Int], lossy: [Foo]?, ref: Object?, string: String?) {
                self.bool = bool
                self.double = double
                self.foobar = foobar
                self.ints = ints
                self.lossy = lossy
                self.ref = ref
                self.string = string
            }

            enum CodingKeys: String, CodingKey {
                case bool = "bool"
                case double = "double"
                case foobar = "foobar"
                case ints = "ints"
                case lossy = "lossy"
                case ref = "ref"
                case string = "string"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.bool = try container.decode(Bool.self, forKey: .bool)
                self.double = try container.decodeIfPresent(Double.self, forKey: .double)
                self.foobar = try container.decodeIfPresent(Foobar.self, forKey: .foobar)
                self.ints = try container.decode([Int].self, forKey: .ints)
                self.lossy = try container.decodeIfPresent(LossyDecodableArray<Foo>.self, forKey: .lossy)?.elements
                self.ref = try container.decodeIfPresent(Object.self, forKey: .ref)
                self.string = try container.decodeIfPresent(String.self, forKey: .string)
            }

            public enum Foobar: String, Codable, CaseIterable, UnknownCaseRepresentable {
                case bar = "bar"
                case baz = "baz"
                case foo = "foo"

                case _unknownCase
                public static let unknownCase = Self._unknownCase

                public static func make() -> Self {
                    ._unknownCase
                }
            }

            public static func make(bool: Bool = false, double: Double? = nil, foobar: Foobar? = nil, ints: [Int] = [], lossy: [Foo]? = nil, ref: Object? = nil, string: String? = nil) -> Self {
                self.init(bool: bool, double: double, foobar: foobar, ints: ints, lossy: lossy, ref: ref, string: string)
            }
        }
        """

    private let expectedWithDefaults = """
        public struct POD: Codable {
            public let bool: Bool

            public let double: Double?

            public let foobar: Foobar?

            public let ints: [Int]

            public let lossy: [Foo]?

            public let ref: Object?

            public let string: String?

            public init(bool: Bool, double: Double?, foobar: Foobar? = DefaultValues.foobar, ints: [Int], lossy: [Foo]?, ref: Object?, string: String?) {
                self.bool = bool
                self.double = double
                self.foobar = foobar
                self.ints = ints
                self.lossy = lossy
                self.ref = ref
                self.string = string
            }

            enum CodingKeys: String, CodingKey {
                case bool = "bool"
                case double = "double"
                case foobar = "foobar"
                case ints = "ints"
                case lossy = "lossy"
                case ref = "ref"
                case string = "string"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.bool = try container.decode(Bool.self, forKey: .bool)
                self.double = try container.decodeIfPresent(Double.self, forKey: .double)
                self.foobar = try container.decodeIfPresent(Foobar.self, forKey: .foobar)
                self.ints = try container.decode([Int].self, forKey: .ints)
                self.lossy = try container.decodeIfPresent(LossyDecodableArray<Foo>.self, forKey: .lossy)?.elements
                self.ref = try container.decodeIfPresent(Object.self, forKey: .ref)
                self.string = try container.decodeIfPresent(String.self, forKey: .string)
            }

            public enum Foobar: String, Codable, CaseIterable, UnknownCaseRepresentable {
                case bar = "bar"
                case baz = "baz"
                case foo = "foo"

                case _unknownCase
                public static let unknownCase = Self._unknownCase

                public static func make() -> Self {
                    ._unknownCase
                }
            }

            public static func make(bool: Bool = false, double: Double? = nil, foobar: Foobar? = nil, ints: [Int] = [], lossy: [Foo]? = nil, ref: Object? = nil, string: String? = nil) -> Self {
                self.init(bool: bool, double: double, foobar: foobar, ints: ints, lossy: lossy, ref: ref, string: string)
            }
        }
        """

    @Test("test POD")
    func testPOD() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "POD")
        let output = String(generator.buffer.dropLast(1))
        expectNoDifference(output, expected)
    }

    @Test("test POD with defaults")
    func testPODWithDefaults() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .init(defaultValues: ["foobar"], skipHeader: true))
        try generator.generate(modelName: "POD")
        let output = String(generator.buffer.dropLast(1))
        expectNoDifference(output, expectedWithDefaults)
    }
}
