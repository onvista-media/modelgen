//
//  Generator.swift
//  
//  Copyright © 2023 onvista media GmbH. All rights reserved.
//

final class Generator {
    private let output = OutputBuffer()
    private let schemas: [String: Schema]
    private let info: Info
    private let classSchemas: Set<String>
    private var importAnyCodable = false

    init(spec: OpenApiSpec, classSchemas: String? = nil) {
        self.schemas = spec.components.schemas
        self.classSchemas = Set((classSchemas ?? "").components(separatedBy: ","))
        self.info = spec.info
    }

    var buffer: String {
        output.buffer
    }

    func generate(modelName: String, skipHeader: Bool = false) {
        guard let schema = schemas[modelName] else {
            fatalError("\(modelName): schema not found")
        }

        output.reset()

        if !skipHeader {
            generateFileHeader(modelName: modelName, schema: schema)
        }
        if schema.discriminator != nil {
            generateModelEnum(modelName: modelName, schema: schema)
        } else if schema.properties != nil {
            generateModelStruct(modelName: modelName, schema: schema)
        } else if schema.allOf != nil {
            generateCompositeStruct(modelName: modelName, schema: schema)
        } else if schema.enumCases != nil {
            generateSimpleEnum(modelName: modelName, schema: schema)
        } else {
            fatalError("\(modelName): don't know how to handle this schema")
        }

        if importAnyCodable {
            print("")
            print("import AnyCodable")
        }
    }

    // MARK: - file header
    private func generateFileHeader(modelName: String, schema: Schema) {
        print("""
        //
        // \(modelName).swift
        // generated by ModelGen \(ModelGen.version)
        //
        // \(info.title)
        //
        // swiftlint:disable:all
        //

        import Foundation

        """)
        comment(schema.description)
    }

    // MARK: - simple enum
    private func generateSimpleEnum(modelName: String, schema: Schema) {
        guard let cases = schema.enumCases else {
            fatalError("\(modelName) has no enum values")
        }

        generateEnum(name: modelName, cases: cases)
    }

    private func generateAllOf(for modelName: String,
                               allOf: [RefOrSchema],
                               addComment: Bool,
                               parentSchema: Schema,
                               generateProperties: ([SwiftProperty]) -> Void
    ) {
        for refOrSchema in allOf {
            switch refOrSchema {
            case .schema(let schema):
                if addComment {
                    comment("MARK: - \(modelName) properties")
                }
                let properties = schema.swiftProperties(for: modelName, parentRequired: parentSchema.required)
                generateProperties(properties)
            case .ref(let ref):
                let refType = ref.swiftType()
                if addComment {
                    comment(#"MARK: - inherited properties from \#(refType.name)"#)
                }
                guard let schema = schemas[refType.name] else {
                    fatalError("\(modelName): no schema for \(refType) found")
                }
                if schema.allOf != nil {
                    fatalError("\(modelName): multi-level interitance is not supported")
                }
                let properties = schema.swiftProperties(for: modelName, parentRequired: parentSchema.required)
                generateProperties(properties)
            }
        }
    }

    // MARK: - composite struct aka child class
    private func generateCompositeStruct(modelName: String, schema: Schema) {
        guard let allOf = schema.allOf else {
            fatalError("\(modelName) has no allOf values")
        }

        block("public struct \(modelName): Codable") {
            generateAllOf(for: modelName, allOf: allOf, addComment: true, parentSchema: schema) {
                generateProperties($0)
            }

            // init method
            print("public init(", terminator: "")
            var sep = ""
            generateAllOf(for: modelName, allOf: allOf, addComment: false, parentSchema: schema) {
                print(sep, terminator: "")
                generateParameters($0)
                sep = ", "
            }

            block(")") {
                generateAllOf(for: modelName, allOf: allOf, addComment: true, parentSchema: schema) {
                    generateAssignments($0)
                }
            }

            // codingkeys
            print("")
            block("enum CodingKeys: String, CodingKey") {
                generateAllOf(for: modelName, allOf: allOf, addComment: false, parentSchema: schema) {
                    generateCodingKeyCases($0)
                }
            }

            // init(from: Decoder)
            print("")
            block("public init(from decoder: Decoder) throws") {
                print("let container = try decoder.container(keyedBy: CodingKeys.self)")
                generateAllOf(for: modelName, allOf: allOf, addComment: false, parentSchema: schema) {
                    generateInitFromDecoderAssignments($0)
                }
            }

            for refOrSchema in allOf {
                if case .schema(let schema) = refOrSchema {
                    generateTypeEnums(schema: schema)
                }
            }
        }

        if let ref = getRef(from: allOf) {
            let protocolName = ref.swiftType().name + "Protocol"
            print("")
            print("extension \(modelName): \(protocolName) {}")
        }
    }

    // MARK: - model struct
    private func generateModelStruct(modelName: String, schema: Schema) {
        let properties = schema.swiftProperties(for: modelName)

        let type = classSchemas.contains(modelName) ? "final class" : "struct"
        block("public \(type) \(modelName): Codable") {
            generateProperties(properties)

            // init method
            print("public init(", terminator: "")
            generateParameters(properties)
            block(")") {
                generateAssignments(properties)
            }

            print("")
            generateCodingKeys(properties)

            print("")
            generateInitFromDecoder(properties)

            generateTypeEnums(schema: schema)
        }
    }

    private func generateCodingKeys(_ props: [SwiftProperty]) {
        block("enum CodingKeys: String, CodingKey") {
            generateCodingKeyCases(props)
        }
    }

    private func generateCodingKeyCases(_ props: [SwiftProperty]) {
        for prop in props {
            print(#"case \#(prop.name) = "\#(prop.specName)""#)
        }
    }

    private func generateInitFromDecoder(_ props: [SwiftProperty]) {
        block("public init(from decoder: Decoder) throws") {
            print("let container = try decoder.container(keyedBy: CodingKeys.self)")
            generateInitFromDecoderAssignments(props)
        }
    }

    private func generateInitFromDecoderAssignments(_ props: [SwiftProperty]) {
        for prop in props {
            let type = prop.type
            let decodeFun = type.isOptional ? "decodeIfPresent" : "decode"
            print("self.\(prop.name) = try container.\(decodeFun)", terminator: "")

            if type.isArray && type.isCustom {
                let optional = type.isOptional ? "?" : ""
                print("(LossyDecodableArray<\(type.name)>.self, forKey: .\(prop.name))\(optional).elements")
            } else {
                print("(\(type.name).self, forKey: .\(prop.name))")
            }

            if type.isAnyCodable {
                importAnyCodable = true
            }
        }
    }

    // MARK: - model enum aka base class
    private func generateModelEnum(modelName: String, schema: Schema) {
        guard let discriminator = schema.discriminator else {
            fatalError("\(modelName) has no discriminator")
        }

        let properties = schema.swiftProperties(for: modelName)
        let discriminatorType = schema.properties?[discriminator.propertyName]

        let discriminatorIsString: Bool
        switch discriminatorType {
        case .ref:
            discriminatorIsString = false
        case .property(let prop):
            assert(prop.type == "string", "\(modelName): unexpected discriminator type")
            discriminatorIsString = true
        case .none:
            fatalError("\(modelName): unknown discriminator type")
        }

        var createBaseType = false
        let discriminatorCases: [DiscriminatorCase]
        if discriminatorIsString {
            var cases = discriminator.swiftCases
            if !cases.contains(where: { $0.mappedModel == modelName}) {
                cases.append(DiscriminatorCase(enumCase: modelName.camelCased(), mappedModel: "\(modelName)Base", rawString: modelName))
                createBaseType = true
            }
            discriminatorCases = cases
        } else {
            discriminatorCases = discriminator.swiftCases
        }

        block("public enum \(modelName): Codable") {
            // enum cases
            for dc in discriminatorCases {
                print("case \(dc.enumCase)(\(dc.mappedModel))")
            }
            print("")

            // init method
            block("public init(from decoder: Decoder) throws") {
                for dc in discriminatorCases {
                    let compare = discriminatorIsString ? #""\#(dc.rawString)""# : ".\(dc.enumCase)"
                    print(#"if let obj = try? \#(dc.mappedModel)(from: decoder), obj.\#(discriminator.propertyName) == \#(compare) {"#)
                    indent {
                        print("self = .\(dc.enumCase)(obj)")
                    }
                    print("} else ", terminator: "")
                }
                block {
                    block("enum DiscriminatorKeys: String, CodingKey") {
                        print(#"case type = "\#(discriminator.propertyName)""#)
                    }
                    print("let container = try decoder.container(keyedBy: DiscriminatorKeys.self)")
                    print("let type = try container.decode(String.self, forKey: .type)")
                    print(#"throw DecodingError.typeMismatch(\#(modelName).self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "unexpected subclass type \(type)"))"#)
                }
            }

            // encode
            print("")
            block("public func encode(to encoder: Encoder) throws") {
                print("switch self {")
                for dc in discriminatorCases {
                    print("case .\(dc.enumCase)(let obj): try obj.encode(to: encoder)")
                }
                print("}")
            }
        }

        print("")
        block("public protocol \(modelName)Protocol") {
            for prop in properties {
                print("var \(prop.name): \(prop.type.propertyType) { get }")
            }
        }

        print("")
        block("extension \(modelName): \(modelName)Protocol") {
            // accessors for all common properties
            for prop in properties {
                block("public var \(prop.name): \(prop.type.propertyType)") {
                    print("switch self {")
                    for dc in discriminatorCases {
                        print("case .\(dc.enumCase)(let obj): return obj.\(prop.name)")
                    }
                    print("}")
                }
                print("")
            }
        }

        if createBaseType {
            print("")
            generateModelStruct(modelName: "\(modelName)Base", schema: schema)
            print("")
            print("extension \(modelName)Base: \(modelName)Protocol {}")
        }
    }

    // MARK: - enums
    private func generateTypeEnums(schema: Schema) {
        guard let properties = schema.properties else {
            return
        }

        for (name, prop) in properties {
            guard case .property(let prop) = prop else {
                continue
            }
            let enumName = SwiftKeywords.safe("\(name.uppercasedFirst())")
            var cases: [String]?

            if let c = prop.enumCases {
                cases = c
            } else if let items = prop.items, case .property(let itemProp) = items, let c = itemProp.enumCases {
                cases = c
            }

            if let cases {
                print("")
                generateEnum(name: enumName, cases: cases)
            }
        }
    }

    private func generateEnum(name: String, cases: [String]) {
        block("public enum \(name): String, Codable, CaseIterable, UnknownCaseRepresentable") {
            for c in cases {
                let name = c.camelCased()
                if "0" ... "9" ~= name.prefix(1) {
                    print(#"case _\#(name) = "\#(c)""#)
                } else {
                    print(#"case \#(SwiftKeywords.safe(name)) = "\#(c)""#)
                }
            }
            print("")
            print("case _unknownCase")
            print("public static let unknownCase = Self._unknownCase")
        }
    }

    // MARK: - properties
    private func generateProperties(_ properties: [SwiftProperty]) {
        for prop in properties {
            comment(prop.comment)
            if prop.deprecated {
                comment("deprecated")
            }
            print("public let \(prop.name): \(prop.type.propertyType)")
            print("")
        }
    }

    private func generateParameters(_ properties: [SwiftProperty]) {
        let params = properties
            .map { "\($0.name): \($0.type.propertyType)" }
            .joined(separator: ", ")
        print(params, terminator: "")
    }

    private func generateAssignments(_ properties: [SwiftProperty]) {
        for prop in properties {
            print("self.\(prop.name) = \(prop.name)")
        }
    }

    private func getRef(from allOf: [RefOrSchema]) -> Ref? {
        for refOrSchema in allOf {
            if case .ref(let ref) = refOrSchema {
                return ref
            }
        }
        return nil
    }
}

// MARK: - output buffer
extension Generator {
    private func print(_ str: String, terminator: String = "\n") {
        output.print(str, terminator: terminator)
    }

    private func indent(closure: () -> Void) {
        output.indent(closure: closure)
    }

    private func block(_ str: String? = nil, closure: () -> Void) {
        output.block(str, closure: closure)
    }

    private func comment(_ str: String?) {
        output.comment(str)
    }
}
