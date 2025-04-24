//
//  InteritanceTest1.swift
//  
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

// test inheritance with an enum as the discriminator

@Suite("Inheritance test 1")
struct InheritanceTest1 {
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
                            "$ref" : "#/components/schemas/AnimalType"
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

        enum DiscriminatorKeys: String, CodingKey {
            case type = "status"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DiscriminatorKeys.self)
            let type = try container.decode(AnimalType.self, forKey: .type)

            if type == .cat, let obj = try? Cat(from: decoder) {
                self = .cat(obj)
            } else if type == .dog, let obj = try? Dog(from: decoder) {
                self = .dog(obj)
            } else {
                throw DecodingError.typeMismatch(Animal.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unexpected subclass type \(type)"))
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .cat(let obj): try obj.encode(to: encoder)
            case .dog(let obj): try obj.encode(to: encoder)
            }
        }

        public static func make() -> Self {
            .cat(.make())
        }
    }

    public protocol AnimalProtocol {
        var status: AnimalType { get }
    }

    extension Animal: AnimalProtocol {
        public var status: AnimalType {
            switch self {
            case .cat(let obj): return obj.status
            case .dog(let obj): return obj.status
            }
        }

    }
    """#

    private let expectedDog =
#"""
public struct Dog: Codable, Hashable {
    // MARK: - inherited properties from Animal
    public let status: AnimalType

    // MARK: - Dog properties
    public let barks: Bool

    public init(status: AnimalType, barks: Bool) {
        // MARK: - inherited properties from Animal
        self.status = status
        // MARK: - Dog properties
        self.barks = barks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(AnimalType.self, forKey: .status)
        self.barks = try container.decode(Bool.self, forKey: .barks)
    }

    public static func make(status: AnimalType = .make(), barks: Bool = false) -> Self {
        self.init(status: status, barks: barks)
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
