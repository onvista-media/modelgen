//
//  Generator.swift
//  
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

final class Generator {
    let output = OutputBuffer()
    let schemas: [String: Schema]
    let info: Info
    let config: Config

    init(spec: OpenApiSpec, config: Config) {
        self.schemas = spec.components.schemas
        self.info = spec.info
        self.config = config
    }

    var buffer: String {
        output.buffer
    }

    func generate(modelName: String) throws {
        guard let schema = schemas[modelName] else {
            fatalError("\(modelName): schema not found")
        }

        output.reset()

        if !config.skipHeader {
            generateFileHeader(modelName: modelName, schema: schema, imports: config.imports)
        }
        if schema.discriminator != nil {
            try generateModelEnum(modelName: modelName, schema: schema)
        } else if schema.properties != nil {
            try generateModelStruct(modelName: modelName, schema: schema)
        } else if schema.allOf != nil {
            try generateCompositeStruct(modelName: modelName, schema: schema)
        } else if schema.enumCases != nil {
            generateSimpleEnum(modelName: modelName, schema: schema)
        } else {
            fatalError("\(modelName): don't know how to handle this schema")
        }
    }

    // MARK: - file header
    func generateFileHeader(modelName: String, schema: Schema?, imports: [String]) {
        print("""
        //
        // \(modelName).swift
        // generated by ModelGen \(ModelGen.version)
        //
        // \(info.title)
        //
        // swiftlint:disable all
        //

        import Foundation
        """)
        imports.forEach {
            print("import \($0)")
        }
        print("")
        if let descr = schema?.description {
            comment(descr)
        }
    }

    // MARK: - simple enum
    private func generateSimpleEnum(modelName: String, schema: Schema) {
        guard let cases = schema.enumCases else {
            fatalError("\(modelName) has no enum values")
        }

        generateEnum(name: modelName, cases: cases)
    }

    private func joinAllProperties(for modelName: String, allOf: [RefOrSchema], parentSchema: Schema) throws -> [SwiftProperty] {
        var properties = [SwiftProperty]()
        for refOrSchema in allOf {
            switch refOrSchema {
            case .schema(let schema):
                properties.append(contentsOf: try schema.swiftProperties(for: modelName, parentRequired: parentSchema.required))
            case .ref(let ref):
                let refType = ref.swiftType()
                guard let schema = schemas[refType.name] else {
                    fatalError("\(modelName): no schema for \(refType) found")
                }
                if schema.allOf != nil {
                    fatalError("\(modelName): multi-level interitance is not supported")
                }
                properties.append(contentsOf: try schema.swiftProperties(for: modelName, parentRequired: parentSchema.required))
            }
        }
        return properties
    }

    private func generateAllOf(
        for modelName: String,
        allOf: [RefOrSchema],
        addComment: Bool,
        parentSchema: Schema,
        generateProperties: ([SwiftProperty]) -> Void
    ) throws {
        for refOrSchema in allOf {
            switch refOrSchema {
            case .schema(let schema):
                if addComment {
                    comment("MARK: - \(modelName) properties")
                }
                let properties = try schema.swiftProperties(for: modelName, parentRequired: parentSchema.required)
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
                let properties = try schema.swiftProperties(for: modelName, parentRequired: parentSchema.required)
                generateProperties(properties)
            }
        }
    }

    // MARK: - composite struct aka child class
    private func generateCompositeStruct(modelName: String, schema: Schema) throws {
        guard let allOf = schema.allOf else {
            fatalError("\(modelName) has no allOf values")
        }

        let sendable = config.sendable ? ", Sendable" : ""
        try block("public struct \(modelName): Codable\(sendable)") {
            try generateAllOf(for: modelName, allOf: allOf, addComment: true, parentSchema: schema) {
                generateProperties($0)
            }

            // init method
            print("public init(", terminator: "")
            var sep = ""
            try generateAllOf(for: modelName, allOf: allOf, addComment: false, parentSchema: schema) {
                print(sep, terminator: "")
                generateParameters($0, defaultValues: config.defaultValues)
                sep = ", "
            }

            try block(")") {
                try generateAllOf(for: modelName, allOf: allOf, addComment: true, parentSchema: schema) {
                    generateAssignments($0)
                }
            }

            // codingkeys
            print("")
            try block("enum CodingKeys: String, CodingKey") {
                try generateAllOf(for: modelName, allOf: allOf, addComment: false, parentSchema: schema) {
                    generateCodingKeyCases($0)
                }
            }

            // init(from: Decoder)
            print("")
            try block("public init(from decoder: Decoder) throws") {
                print("let container = try decoder.container(keyedBy: CodingKeys.self)")
                try generateAllOf(for: modelName, allOf: allOf, addComment: false, parentSchema: schema) {
                    generateInitFromDecoderAssignments($0)
                }
            }

            for refOrSchema in allOf {
                if case .schema(let schema) = refOrSchema {
                    generateTypeEnums(schema: schema)
                }
            }

            // static func make()
            try generateMakeMethod(joinAllProperties(for: modelName, allOf: allOf, parentSchema: schema))
        }

        if let ref = getRef(from: allOf) {
            let protocolName = ref.swiftType().name + "Protocol"
            print("")
            print("extension \(modelName): \(protocolName) {}")
        }
    }

    // MARK: - model struct
    private func generateModelStruct(modelName: String, schema: Schema) throws {
        let properties = try schema.swiftProperties(for: modelName)

        let type = config.classSchemas.contains(modelName) ? "final class" : "struct"
        let sendable = config.sendable ? ", Sendable" : ""
        block("public \(type) \(modelName): Codable\(sendable)") {
            generateProperties(properties)

            // init method
            print("public init(", terminator: "")
            generateParameters(properties, defaultValues: config.defaultValues)
            block(")") {
                generateAssignments(properties)
            }

            print("")
            generateCodingKeys(properties)

            print("")
            generateInitFromDecoder(properties)

            generateTypeEnums(schema: schema)

            // make method
            generateMakeMethod(properties)
        }
    }

    private func generateMakeMethod(_ properties: [SwiftProperty]) {
        print("")
        print("public static func make(", terminator: "")
        let params = properties
            .map {
                "\($0.name): \($0.type.propertyType) = \($0.type.defaultValue)"
            }
            .joined(separator: ", ")
        print(params, terminator: "")
        block(") -> Self") {
            print("self.init(", terminator: "")
            print(properties.map { "\($0.name): \($0.name)"}.joined(separator: ", "), terminator: "")
            print(")")
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

            if type.qualifier == .array && type.isCustom {
                let optional = type.isOptional ? "?" : ""
                print("(LossyDecodableArray<\(type.name)>.self, forKey: .\(prop.name))\(optional).elements")
            } else {
                print("(\(type.baseType).self, forKey: .\(prop.name))")
            }
        }
    }

    // MARK: - model enum aka base class
    private func generateModelEnum(modelName: String, schema: Schema) throws {
        guard let discriminator = schema.discriminator else {
            fatalError("\(modelName) has no discriminator")
        }

        let properties = try schema.swiftProperties(for: modelName)
        let discriminatorType = schema.properties?[discriminator.propertyName]

        let discriminatorIsString: Bool
        let discriminatorTypeName: String
        switch discriminatorType {
        case .ref(let ref):
            discriminatorIsString = false
            discriminatorTypeName = ref.swiftType().name
        case .property(let prop):
            assert(prop.type == "string", "\(modelName): unexpected discriminator type")
            discriminatorIsString = true
            discriminatorTypeName = "String"
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

        if schema.deprecated == true {
            print("@available(*, deprecated)")
        }
        let sendable = config.sendable ? ", Sendable" : ""
        block("public enum \(modelName): Codable\(sendable)") {
            // enum cases
            for dc in discriminatorCases {
                print("case \(dc.enumCase)(\(dc.mappedModel))")
            }
            print("")

            block("enum DiscriminatorKeys: String, CodingKey") {
                print(#"case type = "\#(discriminator.propertyName)""#)
            }
            print("")

            // init method
            block("public init(from decoder: Decoder) throws") {
                print("let container = try decoder.container(keyedBy: DiscriminatorKeys.self)")
                print("let type = try container.decode(\(discriminatorTypeName).self, forKey: .type)")
                print("")
                for dc in discriminatorCases {
                    let compare = discriminatorIsString ? #""\#(dc.rawString)""# : ".\(dc.enumCase)"
                    print("if type == \(compare), let obj = try? \(dc.mappedModel)(from: decoder) {")
                    indent {
                        print("self = .\(dc.enumCase)(obj)")
                    }
                    print("} else ", terminator: "")
                }
                block {
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

            // make method
            print("")
            block("public static func make() -> Self") {
                if createBaseType {
                    print(".\(modelName.camelCased())(.make())")
                } else {
                    guard let first = discriminatorCases.first else { return }
                    print(".\(first.enumCase)(.make())")
                }
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
            try generateModelStruct(modelName: "\(modelName)Base", schema: schema)
            print("")
            print("extension \(modelName)Base: \(modelName)Protocol {}")
        }
    }

    // MARK: - enums
    private func generateTypeEnums(schema: Schema) {
        guard let properties = schema.properties else {
            return
        }

        for name in properties.keys.sorted(by: <) {
            guard let prop = properties[name], case .property(let prop) = prop else {
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
        if cases.isEmpty {
            fatalError("enum \(name) has no cases")
        }

        let sortedCases = Set(cases).sorted(by: <)
        let sendable = config.sendable ? ", Sendable" : ""
        block("public enum \(name): String, Codable, CaseIterable, UnknownCaseRepresentable\(sendable)") {
            for c in sortedCases {
                let name = c.camelCased()
                print(#"case \#(SwiftKeywords.safe(name)) = "\#(c)""#)
            }
            print("")
            print("case _unknownCase")
            print("public static let unknownCase = Self._unknownCase")

            print("")
            block("public static func make() -> Self") {
                print("._unknownCase")
            }
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

    private func generateParameters(_ properties: [SwiftProperty], defaultValues: [String]) {
        let params = properties
            .map {
                let param = "\($0.name): \($0.type.propertyType)"
                if defaultValues.contains($0.name) {
                    return "\(param) = DefaultValues.\($0.name)"
                }
                return param
            }
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
    func print(_ str: String, terminator: String = "\n") {
        output.print(str, terminator: terminator)
    }

    func indent(closure: () -> Void) {
        output.indent(closure: closure)
    }

    func block<T>(_ str: String? = nil, closure: () throws -> T) rethrows -> T {
        try output.block(str, closure: closure)
    }

    func comment(_ str: String?) {
        output.comment(str)
    }
}
