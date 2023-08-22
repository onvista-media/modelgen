//
//  OpenApiSpec.swift
//
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

struct OpenApiSpec: Decodable {
    let components: Components
    let info: Info
    let paths: [ String: [String: Request] ]
}

struct Info: Decodable {
    let title: String
}

struct Request: Decodable {
    let tags: [String]
    let operationId: String
    let parameters: [Parameter]?
    let requestBody: RequestBody?
    let responses: [String: Response]
}

struct RequestBody: Decodable {
    let content: [String: SchemaContainer]
}

struct Parameter: Decodable {
    let name: String
    let `in`: String
    let description: String?
    let schema: Property
    let required: Bool?
}

struct Response: Decodable {
    let description: String?
    let content: [String: SchemaContainer]?
}

struct SchemaContainer: Decodable {
    let schema: RefOrSchema?
}

struct Components: Decodable {
    let schemas: [String: Schema]
}

struct Schema: Decodable {
    let type: String
    let properties: [String: RefOrProperty]?
    let required: [String]?
    let allOf: [RefOrSchema]?
    let description: String?
    let discriminator: Discriminator?
    let enumCases: [String]?

    enum CodingKeys: String, CodingKey {
        case type, properties, required, allOf, description, discriminator
        case enumCases = "enum"
    }
}

struct Discriminator: Decodable {
    let propertyName: String
    let mapping: [String: String]
}

struct Property: Decodable {
    let type: String
    let description: String?
    let format: String?
    let items: RefOrProperty?
    let deprecated: Bool?
    let enumCases: [String]?
    let additionalProperties: RefOrProperty?

    enum CodingKeys: String, CodingKey {
        case type, description, format, items, deprecated
        case enumCases = "enum"
        case additionalProperties
    }
}

struct Ref: Decodable {
    let ref: String

    enum CodingKeys: String, CodingKey {
        case ref = "$ref"
    }
}

indirect enum RefOrProperty: Decodable {
    case ref(Ref)
    case property(Property)

    init(from decoder: Decoder) throws {
        if let ref = try? Ref(from: decoder) {
            self = .ref(ref)
        } else if let prop = try? Property(from: decoder) {
            self = .property(prop)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unknown ref/property"))
        }
    }
}

enum RefOrSchema: Decodable {
    case ref(Ref)
    case schema(Schema)

    init(from decoder: Decoder) throws {
        if let ref = try? Ref(from: decoder) {
            self = .ref(ref)
        } else if let schema = try? Schema(from: decoder) {
            self = .schema(schema)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unknown ref/schema"))
        }
    }
}
