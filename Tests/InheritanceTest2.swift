//
//  InteritanceTest2.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

import XCTest
@testable import modelgen

// test inheritance with a string as the discriminator

final class InheritanceTest2: XCTestCase {
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
    public enum Animal: Codable {
        case cat(Cat)
        case dog(Dog)

        public init(from decoder: Decoder) throws {
            if let obj = try? Cat(from: decoder), obj.status == "cat" {
                self = .cat(obj)
            } else if let obj = try? Dog(from: decoder), obj.status == "dog" {
                self = .dog(obj)
            } else {
                enum DiscriminatorKeys: String, CodingKey {
                    case type = "status"
                }
                let container = try decoder.container(keyedBy: DiscriminatorKeys.self)
                let type = try container.decode(String.self, forKey: .type)
                throw DecodingError.typeMismatch(Animal.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unexpected subclass type \(type)"))
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .cat(let obj): try obj.encode(to: encoder)
            case .dog(let obj): try obj.encode(to: encoder)
            }
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
            }
        }

    }
    """#

    private let expectedDog =
    #"""
    public struct Dog: Codable {
        // MARK: - inherited properties from Animal
        public let status: String

        // MARK: - Dog properties
        public let barks: Bool

        public init(status: String, barks: Bool) {
            // MARK: - inherited properties from Animal
            self.status = status
            // MARK: - Dog properties
            self.barks = barks
        }
    }

    extension Dog: AnimalProtocol {}
    """#

    func testBaseClass() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        generator.generate(modelName: "Animal", skipHeader: true)
        XCTAssertEqual(String(generator.buffer.dropLast(1)), multiline: expectedBase)
    }

    func testChildClassDog() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec)
        generator.generate(modelName: "Dog", skipHeader: true)
        XCTAssertEqual(String(generator.buffer.dropLast(1)), multiline: expectedDog)
    }
}
