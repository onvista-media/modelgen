//
//  CodingKeyTest.swift
//
//  Copyright © 2025 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

@Suite("Coding Key test")
struct CodingKeyTest {
    private let specNoCodingkeys = """
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

    private let specWithCodingKeys = """
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
                        "self" : {
                            "type" : "boolean"
                        },
                        "class" : {
                            "type" : "array",
                            "items" : {
                                "type" : "integer"
                            }
                        },
                        "42" : {
                            "type": "array",
                            "items": {
                                "$ref": "#/components/schemas/Foo"
                            }
                        },
                        "_" : {
                            "type" : "string"
                        },
                        "double" : {
                            "type" : "number"
                        },
                        "Result" : {
                            "type" : "string",
                            "enum" : [ "foo", "bar", "baz" ]
                        }
                    }
                }
            }
        }
    }
    """

    private let expectedNoCodingKeys = """
        public struct POD: Codable, Hashable {
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

            public enum Foobar: String, Codable, CaseIterable, UnknownCaseRepresentable, Hashable {
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

    private let expectedWithCodingKeys = """
        public struct POD: Codable, Hashable {
            public let _42: [Foo]?

            public let _Result: _Result?

            public let __: String?

            public let _class: [Int]?

            public let double: Double?

            public let ref: Object?

            public let _self: Bool?

            public init(_42: [Foo]?, _Result: _Result?, __: String?, _class: [Int]?, double: Double?, ref: Object?, _self: Bool?) {
                self._42 = _42
                self._Result = _Result
                self.__ = __
                self._class = _class
                self.double = double
                self.ref = ref
                self._self = _self
            }

            enum CodingKeys: String, CodingKey {
                case _42 = "42"
                case _Result = "Result"
                case __ = "_"
                case _class = "class"
                case double = "double"
                case ref = "ref"
                case _self = "self"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self._42 = try container.decodeIfPresent(LossyDecodableArray<Foo>.self, forKey: ._42)?.elements
                self._Result = try container.decodeIfPresent(_Result.self, forKey: ._Result)
                self.__ = try container.decodeIfPresent(String.self, forKey: .__)
                self._class = try container.decodeIfPresent([Int].self, forKey: ._class)
                self.double = try container.decodeIfPresent(Double.self, forKey: .double)
                self.ref = try container.decodeIfPresent(Object.self, forKey: .ref)
                self._self = try container.decodeIfPresent(Bool.self, forKey: ._self)
            }

            public enum _Result: String, Codable, CaseIterable, UnknownCaseRepresentable, Hashable {
                case bar = "bar"
                case baz = "baz"
                case foo = "foo"

                case _unknownCase
                public static let unknownCase = Self._unknownCase

                public static func make() -> Self {
                    ._unknownCase
                }
            }

            public static func make(_42: [Foo]? = nil, _Result: _Result? = nil, __: String? = nil, _class: [Int]? = nil, double: Double? = nil, ref: Object? = nil, _self: Bool? = nil) -> Self {
                self.init(_42: _42, _Result: _Result, __: __, _class: _class, double: double, ref: ref, _self: _self)
            }
        }
        """

    @Test("test no coding keys")
    func testNoCodingKeys() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: specNoCodingkeys.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "POD")
        let output = String(generator.buffer.dropLast(1))
        expectNoDifference(output, expectedNoCodingKeys)
    }

    @Test("test with coding keys")
    func testCodingKeys() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: specWithCodingKeys.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .init(defaultValues: ["foobar"], skipHeader: true))
        try generator.generate(modelName: "POD")
        let output = String(generator.buffer.dropLast(1))
        expectNoDifference(output, expectedWithCodingKeys)
    }
}
