//
//  AnyJSONModelTest.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

import Foundation
import CustomDump
import Testing
@testable import modelgen

@Suite("AnyJSONMOdel Tests")
struct AnyJSONModelTest {
    private let spec = """
    {
        "info": {
            "title": "test spec"
        },
        "components": {
            "schemas": {
                "BookingMetadata" : {
                    "type" : "object",
                    "additionalProperties" : {
                        "type" : "string"
                    }
                },
                "CreateOrUpdateBookingParamsMetadata" : {
                  "type" : "object",
                  "additionalProperties" : {
                     "$ref" : "#/components/schemas/AnyJSONModel"
                  },
                },
                "AnyJSONModel" : {
                    "type" : "object",
                    "properties" : {
                      "stringValue" : {
                        "type" : "string"
                      },
                      "doubleValue" : {
                        "type" : "number",
                        "format" : "double"
                      },
                      "integerValue" : {
                        "type" : "integer",
                        "format" : "int64"
                      },
                      "booleanValue" : {
                        "type" : "boolean"
                      },
                      "mapValue" : {
                        "type" : "object",
                        "additionalProperties" : {
                            "type" : "object"
                        }
                      }
                    }
                }
            }
        }
    }
    """

    private let expected = """
    public struct AnyJSONModel: Codable {
        public let booleanValue: Bool?

        public let doubleValue: Double?

        public let integerValue: Int?

        public let mapValue: [String: AnyCodable]?

        public let stringValue: String?

        public init(booleanValue: Bool?, doubleValue: Double?, integerValue: Int?, mapValue: [String: AnyCodable]?, stringValue: String?) {
            self.booleanValue = booleanValue
            self.doubleValue = doubleValue
            self.integerValue = integerValue
            self.mapValue = mapValue
            self.stringValue = stringValue
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.booleanValue = try container.decodeIfPresent(Bool.self, forKey: .booleanValue)
            self.doubleValue = try container.decodeIfPresent(Double.self, forKey: .doubleValue)
            self.integerValue = try container.decodeIfPresent(Int.self, forKey: .integerValue)
            self.mapValue = try container.decodeIfPresent([String: AnyCodable].self, forKey: .mapValue)
            self.stringValue = try container.decodeIfPresent(String.self, forKey: .stringValue)
        }

        public static func make(booleanValue: Bool? = nil, doubleValue: Double? = nil, integerValue: Int? = nil, mapValue: [String: AnyCodable]? = nil, stringValue: String? = nil) -> Self {
            self.init(booleanValue: booleanValue, doubleValue: doubleValue, integerValue: integerValue, mapValue: mapValue, stringValue: stringValue)
        }
    }
    """

    @Test("AnyJSONModel")
    func testAnyJSONModel() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "AnyJSONModel")
        expectNoDifference(String(generator.buffer.dropLast(1)), expected)
    }

    @Test("BookingMetadata")
    func testBookingMetadata() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "BookingMetadata")
        expectNoDifference(String(generator.buffer.dropLast(1)), "public typealias BookingMetadata = [String: String]")
    }

    @Test("CreateOrUpdateBookingParamsMetadata")
    func testCreateOrUpdateBookingParamsMetadata() throws {
        let spec = try JSONDecoder().decode(OpenApiSpec.self, from: spec.data(using: .utf8)!)
        let generator = Generator(spec: spec, config: .test)
        try generator.generate(modelName: "CreateOrUpdateBookingParamsMetadata")
        expectNoDifference(String(generator.buffer.dropLast(1)), "public typealias CreateOrUpdateBookingParamsMetadata = [String: AnyJSONModel]")
    }

}
