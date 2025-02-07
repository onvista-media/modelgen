//
//  SwiftProperty.swift
//
//  Copyright © 2024 onvista media GmbH. All rights reserved.
//

struct SwiftProperty {
    /// name as in the open api spec
    let specName: String

    /// name as used in the generated source, may use initial `_` to avoid clashes with swift keywords
    let name: String

    let type: SwiftType

    let comment: String?

    let deprecated: Bool

    init(name: String,
         type: SwiftType,
         comment: String? = nil,
         deprecated: Bool = false
    ) {
        self.specName = name
        self.name = SwiftKeywords.safe(name)
        self.type = type
        self.comment = comment
        self.deprecated = deprecated
    }
}

struct SwiftType {
    let name: String
    let isOptional: Bool
    let isCustom: Bool
    let qualifier: CollectionQualifier

    enum CollectionQualifier {
        case scalar, array, dictionary
    }

    init(name: String, isOptional: Bool, isCustom: Bool, qualifier: CollectionQualifier) {
        self.name = SwiftKeywords.safe(name)
        self.isOptional = isOptional
        self.isCustom = isCustom
        self.qualifier = qualifier
    }

    var propertyType: String {
        let isArray = qualifier == .array
        let openBracket = isArray ? "[" : ""
        let closeBracket = isArray ? "]" : ""
        let optional = isOptional ? "?" : ""
        return "\(openBracket)\(name)\(closeBracket)\(optional)"
    }

    var baseType: String {
        let isArray = qualifier == .array
        let openBracket = isArray ? "[" : ""
        let closeBracket = isArray ? "]" : ""
        return "\(openBracket)\(name)\(closeBracket)"
    }

    var defaultValue: String {
        if isOptional {
            return "nil"
        }
        switch qualifier {
        case .array: return "[]"
        case .dictionary: return "[:]"
        case .scalar:
            switch name {
            case "Int": return "0"
            case "Double": return "0.0"
            case "Bool": return "false"
            case "String": return "\"\""
            case "Date": return ".init()"
            default: return ".make()"
            }
        }
    }
}

enum TypeError: Error {
    case noResponseType
    case unknownPropertyType
}
