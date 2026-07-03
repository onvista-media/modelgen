//
//  OpenApiSpec.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

struct OpenApiSpec: Decodable {
    let components: Components
    let info: Info
    let paths: [ String: [String: Request] ]?
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
    let deprecated: Bool?
    let summary: String?
    let description: String?
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
    let deprecated: Bool?

    enum CodingKeys: String, CodingKey {
        case type, properties, required, allOf, description, discriminator, deprecated
        case enumCases = "enum"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.properties = try container.decodeIfPresent([String : RefOrProperty].self, forKey: .properties)
        self.required = try container.decodeIfPresent([String].self, forKey: .required)
        self.allOf = try container.decodeIfPresent([RefOrSchema].self, forKey: .allOf)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.discriminator = try container.decodeIfPresent(Discriminator.self, forKey: .discriminator)
        self.deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated)
        do {
            self.enumCases = try container.decodeIfPresent([String].self, forKey: .enumCases)
        } catch {
            self.enumCases = nil
        }
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
