//
//  InteritanceTest2.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

// test inheritance with a string as the discriminator
@Suite("Interitance test 2")
struct InheritanceTest2 {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "Animal" : {
                    "required" : [ "status" ],
                    "type" : "object",
                    "properties" : {
                        "status" : {
                            "type" : "string"
                        }
                    },
                    "discriminator" : {
                        "propertyName" : "status",
                        "mapping" : {
                            "dog" : "#/components/schemas/Dog",
                            "cat" : "#/components/schemas/Cat"
                        }
                    }
                },
                "Dog": {
                    "type" : "object",
                    "allOf" : [ {
                          "$ref" : "#/components/schemas/Animal"
                        }, {
                          "type" : "object",
                          "required": [ "barks" ],
                          "properties" : {
                            "barks" : {
                              "type" : "boolean"
                            },
                            "array" : {
                              "type": "array",
                              "items": {
                                "$ref": "#/components/schemas/Foo"
                              }
                            },
                            "foobar" : {
                              "type" : "string",
                              "enum" : [ "foo", "bar", "baz" ]
                            }
                          }
                        }
                    ]
                }
            }
        }
    }
    """

    private let expectedBase = #"""
    public enum Animal: Codable, Hashable {
        case cat(Cat)
        case dog(Dog)
        case animal(AnimalBase)

        enum DiscriminatorKeys: String, CodingKey {
            case type = "status"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DiscriminatorKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            if type == "cat", let obj = try? Cat(from: decoder) {
                self = .cat(obj)
            } else if type == "dog", let obj = try? Dog(from: decoder) {
                self = .dog(obj)
            } else if type == "Animal", let obj = try? AnimalBase(from: decoder) {
                self = .animal(obj)
            } else {
                throw DecodingError.typeMismatch(Animal.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unexpected subclass type \(type)"))
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .cat(let obj): try obj.encode(to: encoder)
            case .dog(let obj): try obj.encode(to: encoder)
            case .animal(let obj): try obj.encode(to: encoder)
            }
        }

        public static func make() -> Self {
            .animal(.make())
        }
    }

    public protocol AnimalProtocol {
        var status: String { get }
    }

    extension Animal: AnimalProtocol {
        public var status: String {
            switch self {
            case .cat(let obj): return obj.status
            case .dog(let obj): return obj.status
            case .animal(let obj): return obj.status
            }
        }

    }

    public struct AnimalBase: Codable, Hashable {
        public let status: String

        public init(status: String) {
            self.status = status
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.status = try container.decode(String.self, forKey: .status)
        }

        public static func make(status: String = "") -> Self {
            self.init(status: status)
        }
    }

    extension AnimalBase: AnimalProtocol {}
    """#

    private let expectedDog =
#"""
public struct Dog: Codable, Hashable {
    // MARK: - inherited properties from Animal
    public let status: String

    // MARK: - Dog properties
    public let array: [Foo]?

    public let barks: Bool

    public let foobar: Foobar?

    public init(status: String, array: [Foo]?, barks: Bool, foobar: Foobar?) {
        // MARK: - inherited properties from Animal
        self.status = status
        // MARK: - Dog properties
        self.array = array
        self.barks = barks
        self.foobar = foobar
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(String.self, forKey: .status)
        self.array = try container.decodeIfPresent(LossyDecodableArray<Foo>.self, forKey: .array)?.elements
        self.barks = try container.decode(Bool.self, forKey: .barks)
        self.foobar = try container.decodeIfPresent(Foobar.self, forKey: .foobar)
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

    public static func make(status: String = "", array: [Foo]? = nil, barks: Bool = false, foobar: Foobar? = nil) -> Self {
        self.init(status: status, array: array, barks: barks, foobar: foobar)
    }
}

extension Dog: AnimalProtocol {}
"""#

    @Test("test base class")
    func testBaseClass() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "Animal")
        expectNoDifference(String(generator.buffer.dropLast(1)), expectedBase)
    }

    @Test("test child class dog")
    func testChildClassDog() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "Dog")
        expectNoDifference(String(generator.buffer.dropLast(1)), expectedDog)
    }
}
